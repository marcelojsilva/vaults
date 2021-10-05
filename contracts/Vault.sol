// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
import "./SafeMath.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    uint public taxForNonBabyDogeCoin;
    IERC20 public babydoge;

    struct UserInfo {
        uint amount;
        uint weight;
        uint rewardDebt;
        uint rewardWithdraw;
        uint lockTime;
        uint lockDays;
        uint lastRewardDay;
        bool exists;
    }
    mapping(uint => mapping(address => UserInfo)) public userInfo;

    struct TotalDay {
        uint amount;
        uint weight;
    }
    mapping(uint => mapping(uint => TotalDay)) public totalDay;

    struct VaultInfo {
        IERC20 token;
        uint amountReward;
        uint vaultTokenTax;
        uint startVault;
        uint lockDays;
        uint userCount;
        uint usersAmount;
        uint usersWeight;
        bool isLpVault;
        bool paused;
        uint lastTotalDay;
    }
    VaultInfo[] public vaultInfo;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);

    constructor(IERC20 _babydoge, uint _taxForNonBabyDogeCoin) {
        babydoge = _babydoge;
        taxForNonBabyDogeCoin = _taxForNonBabyDogeCoin;
    }

    function createVault(
        IERC20 _token,
        bool _isLp,
        uint _lockDays,
        uint _amount
    ) public {
        require(_token.balanceOf(msg.sender) >= _amount, "User has no tokens");
        uint tax = 0;
        if (!isBabyDoge(_token)) {
            tax = taxForNonBabyDogeCoin;
        }
        uint _amountReserve = (_amount / 100) * (100 - tax);
        uint _tax = (_amount / 100) * tax;
        
        vaultInfo.push(
            VaultInfo({
                token: _token,
                amountReward: _amountReserve,
                vaultTokenTax: _tax,
                startVault: block.timestamp,
                lockDays: _lockDays,
                userCount: 0,
                usersAmount: 0,
                usersWeight: 0,
                isLpVault: _isLp,
                paused: false,
                lastTotalDay: block.timestamp.div(1 days).sub(1)
            })
        );
        uint vaultId = vaultInfo.length - 1;
        uint _today = today();
        TotalDay storage _totalDay = totalDay[vaultId][_today];
        _totalDay.amount = 0;

        require(
            _token.transferFrom(address(msg.sender), address(this), _amount),
            "Can't transfer tokens."
        );
    }
    
    function withdrawTax(uint _vid) public onlyOwner {
        VaultInfo storage vault = vaultInfo[_vid];
        if (vault.vaultTokenTax > 0) {
            require(vault.token.transfer(owner(), vault.vaultTokenTax), "Can't transfer tax to owner");
            vault.vaultTokenTax = 0;
        }
    }

    function isBabyDoge(IERC20 _token) internal view returns (bool) {
        return address(_token) == address(babydoge);
    }

    function getUserInfo(uint _vid, address _user)
        public view 
        returns (
            uint,
            uint,
            uint,
            uint,
            uint
        )
    {
        UserInfo memory user = userInfo[_vid][_user];
        return (
            user.amount,
            user.weight,
            user.rewardDebt,
            user.rewardWithdraw,
            user.lockTime
        );
    }

    function getVault(uint _vid) public view returns (IERC20, uint, uint, uint, uint, uint){
        VaultInfo memory vault = vaultInfo[_vid];
        return (
            vault.token,
            vault.amountReward,
            vault.vaultTokenTax,
            vault.lockDays,
            vault.startVault,
            endVaultDay(_vid)
        );
    }

    function endVaultDay(uint _vid) internal view returns (uint) {
        VaultInfo memory vault = vaultInfo[_vid];
        return vault.startVault.add(vault.lockDays * 24 * 60 * 60);
    }

    function today() internal view returns (uint) {
        return block.timestamp.div(1 days);
    }

    function yestarday(uint _vid) internal view returns (uint) {
        uint endVault = endVaultDay(_vid);
        return block.timestamp > endVault
            ? endVault.div(1 days).sub(1)
            : block.timestamp.div(1 days).sub(1);
    }

    function syncDays(uint _vid) internal {
        VaultInfo memory vault = vaultInfo[_vid];
        uint _yesterday = yestarday(_vid);
        uint _today = today();
        //Return if already sync
        if (vault.lastTotalDay >= _yesterday) {
            return;
        }

        TotalDay memory _lastTotalDay = totalDay[_vid][vault.lastTotalDay];
        //Sync days without movements
        for (uint d = vault.lastTotalDay + 1; d < _today; d += 1) {
            TotalDay storage _totalDay = totalDay[_vid][d];
            _totalDay.amount = _lastTotalDay.amount;
            _totalDay.weight = _lastTotalDay.weight;
        }
    }

    function deposit(
        uint _vid,
        uint _lockDays,
        uint value
    ) external returns (bool) {
        require(value > 0, "Deposit must be greater than zero");
        VaultInfo storage vault = vaultInfo[_vid];
        uint endVault = endVaultDay(_vid);
        require(vault.paused == false, "Vault paused");
        require(block.timestamp >= vault.startVault, "Vault not started");
        require(block.timestamp <= endVault, "Vault finiched");
        require(
            vault.token.transferFrom(address(msg.sender), address(this), value)
        );
        uint _today = today();

        UserInfo storage user = userInfo[_vid][msg.sender];
        uint stakeWeight = 0;
        if (!user.exists) {
            user.exists = true;
            uint _lockTime = block.timestamp.add(_lockDays*24*60*60);
            _lockTime = _lockTime > endVault
                ? endVault 
                : _lockTime;
            user.lockTime = _lockTime;
            user.lockDays = _lockDays;
            user.lastRewardDay = _today;
            vault.userCount += 1;
            stakeWeight = (user.lockDays.mul(1e9))
                .div(vault.lockDays)
                .add(1e9);
            user.weight = stakeWeight;
        } else {
            //New deposits of the same user with the same weight as the first one
            stakeWeight = 0;
        }

        user.amount += value;

        syncDays(_vid);
        
        vault.lastTotalDay = _today;
        vault.usersAmount += value;
        vault.usersWeight += stakeWeight;
        
        TotalDay storage _totalDay = totalDay[_vid][_today];
        _totalDay.amount = vault.usersAmount;
        _totalDay.weight = vault.usersWeight;

        return true;
    }

    function withdraw(uint _vid) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.paused == false, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];
        require(user.lockTime <= block.timestamp, "User in lock time");
        
        syncDays(_vid);

        uint _today = today();

        uint userReward = calcRewardsUser(_vid, msg.sender);
        
        user.lastRewardDay = _today;
        user.rewardDebt += userReward;
        uint total = user.amount + userReward;

        require(vault.token.transfer(address(msg.sender), total));

        user.rewardWithdraw = userReward;
        user.exists = false;

        vault.userCount = vault.userCount - 1;
        vault.usersAmount -= user.amount;
        vault.usersWeight -= user.weight;
        vault.lastTotalDay = user.lastRewardDay;
        
        TotalDay storage _totalDay = totalDay[_vid][_today];
        _totalDay.amount = vault.usersAmount;
        _totalDay.weight = vault.usersWeight;

        user.amount = 0;
        user.weight = 0;
    }

    function calcRewardsUser(uint _vid, address _user) public view returns (uint) {
        UserInfo memory user = userInfo[_vid][_user];
        VaultInfo memory vault = vaultInfo[_vid];
        uint _yesterday = yestarday(_vid);
        uint reward = 0;
        uint rewardDay = vault.amountReward.div(vault.lockDays);
        uint weightedAverage = 0;
        uint userWeight = user.weight;
        for (uint d = user.lastRewardDay; d <= _yesterday; d += 1) {
            TotalDay memory _totalDay = totalDay[_vid][d];
            if (_totalDay.weight > 0) {
                weightedAverage = _totalDay.amount.div(_totalDay.weight);
                reward += rewardDay.mul(weightedAverage.mul(userWeight).mul(1e9).div(_totalDay.amount)).div(1e9);
                // console.log("Dia %s user %", d, msg.sender);
                // console.log("_totalDay.amount %s, _totalDay.weight %s, rewardDay %s",_totalDay.amount, _totalDay.weight, rewardDay.div(1e9));
                // console.log(" weightedAverage %s, userWeight %s, reward %s", weightedAverage, userWeight, reward);
                // console.log("% %s", weightedAverage.mul(userWeight).mul(1e9).div(_totalDay.amount));
                // console.log(" ");
            }
        }
        return reward;
    }
}
