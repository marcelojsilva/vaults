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

    uint public taxForNonBabyDogeCoin = 0;

    struct UserInvest {
        uint amount;
        uint weight;
    }
    UserInvest[] private userInvest;

    struct UserInfo {
        uint userInvestPos;
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
        // UserInvest[] userInvest;
        bool exists;
    }
    mapping(uint => mapping(uint => TotalDay)) public totalDay;

    struct VaultInfo {
        IERC20 token;
        uint amountReward;
        uint vaultTokenTax;
        uint startVault;
        uint endVault;
        uint lockDays;
        uint userCount;
        uint usersAmount;
        bool isLpVault;
        bool paused;
        uint lastTotalDay;
    }
    VaultInfo[] public vaultInfo;

    //address public babydogeAddr = 0xc748673057861a797275cd8a068abb95a902e8de;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);

    constructor(uint _taxForNonBabyDogeCoin) {
        taxForNonBabyDogeCoin = _taxForNonBabyDogeCoin;
    }

    function createVault(
        IERC20 _token,
        bool _isLp,
        uint _lockDays,
        uint _amount
    ) public {
        require(_token.balanceOf(msg.sender) >= _amount, "User has no tokens");
        //TODO validate tax free for babydoge
        uint _amountReserve = (_amount / 100) *
            (100 - taxForNonBabyDogeCoin);
        uint _tax = (_amount / 100) * taxForNonBabyDogeCoin;
        
        vaultInfo.push(
            VaultInfo({
                token: _token,
                amountReward: _amountReserve,
                vaultTokenTax: _tax,
                startVault: block.timestamp,
                endVault: block.timestamp.add(_lockDays * 24 * 60 * 60),
                lockDays: _lockDays,
                userCount: 0,
                usersAmount: 0,
                isLpVault: _isLp,
                paused: false,
                lastTotalDay: block.timestamp.div(1 days).sub(1)
            })
        );
        uint vaultId = vaultInfo.length - 1;
        uint _today = today();
        TotalDay storage _totalDay = totalDay[vaultId][_today];
        _totalDay.amount = 0;
        _totalDay.exists = true;

        require(
            _token.transferFrom(address(msg.sender), address(this), _amount),
            "Can't transfer tokens."
        );
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
            userInvest[user.userInvestPos].amount,
            userInvest[user.userInvestPos].weight,
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
            vault.endVault
        );
    }

    function deposit(
        uint _vid,
        uint _lockDays,
        uint value
    ) external returns (bool) {
        require(value > 0, "Deposit must be greater than zero");
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.paused == false, "Vault paused");
        require(block.timestamp >= vault.startVault, "Vault not started");
        require(block.timestamp <= vault.endVault, "Vault finiched");
        require(
            vault.token.transferFrom(address(msg.sender), address(this), value)
        );
        uint _today = today();

        UserInfo storage user = userInfo[_vid][msg.sender];
        uint stakeWeight = (user.lockDays.mul(1e9))
            .div(vault.lockDays)
            .add(1e9);
        if (!user.exists) {
            user.exists = true;
            uint _lockTime = block.timestamp.add(_lockDays*24*60*60);
            _lockTime = _lockTime > vault.endVault
                ? vault.endVault 
                : _lockTime;
            user.lockTime = _lockTime;
            user.lockDays = _lockDays;
            userInvest.push(UserInvest(0,0));
            uint userInvestPos = userInvest.length - 1;
            user.userInvestPos = userInvestPos;
            user.lastRewardDay = _today;
            vault.userCount += 1;
            //Novos depósitos do usuário devem manter o mesmo peso do primeiro depósito
            userInvest[user.userInvestPos].weight = stakeWeight;
        } else {
            stakeWeight = 0;
        }

        userInvest[user.userInvestPos].amount += value;

        TotalDay storage _totalDay = totalDay[_vid][_today];
        if (!_totalDay.exists){
            syncDays(_vid);
        }
        _totalDay.amount += value;
        _totalDay.weight += stakeWeight;
        // _totalDay.userInvest = userInvest;
        vault.lastTotalDay = _today;
        vault.usersAmount += value;

        return true;
    }

    function today() internal view returns (uint) {
        return block.timestamp.div(1 days);
    }

    function yestarday(uint _vid) internal view returns (uint) {
        VaultInfo memory vault = vaultInfo[_vid];
        return block.timestamp > vault.endVault
            ? vault.endVault
            : block.timestamp.div(1 days).sub(1);
    }

    function syncDays(uint _vid) public {
        VaultInfo memory vault = vaultInfo[_vid];
        uint _yesterday = yestarday(_vid);
        uint _today = today();
        //Valida se já foi calculado o último dia
        if (vault.lastTotalDay >= _yesterday) {
            return;
        }

        TotalDay memory _lastTotalDay = totalDay[_vid][vault.lastTotalDay];
        //Atualiza dias que não tiveram depósito ou saque
        for (uint d = vault.lastTotalDay + 1; d <= _today; d += 1) {
            TotalDay storage _totalDay = totalDay[_vid][d];
            _totalDay.amount = _lastTotalDay.amount;
            _totalDay.weight = _lastTotalDay.weight;
            _totalDay.exists = true;
        }

    }

    function withdraw(uint _vid) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.paused == false, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];
        require(user.lockTime <= block.timestamp, "User in lock time");

        syncDays(_vid);
        uint userReward = calcRewardsUser(_vid, msg.sender);
        user.lastRewardDay = today();
        uint amount = userInvest[user.userInvestPos].amount;
        user.rewardDebt += userReward;
        uint total = amount + userReward;

        require(vault.token.transfer(address(msg.sender), total));

        user.rewardWithdraw = userReward;
        user.exists = false;
        
        userInvest[user.userInvestPos].amount = 0;
        userInvest[user.userInvestPos].weight = 0;

        vault.userCount = vault.userCount - 1;
        vault.usersAmount -= amount;
    }

    function calcRewardsUser(uint _vid, address _user) public view returns (uint) {
        UserInfo memory user = userInfo[_vid][_user];
        VaultInfo memory vault = vaultInfo[_vid];
        uint _yesterday = yestarday(_vid);
        uint reward = 0;
        uint rewardDay = vault.amountReward.div(vault.lockDays);
        uint weightedAverage = 0;
        uint userWeight = userInvest[user.userInvestPos].weight;
        for (uint d = user.lastRewardDay; d <= _yesterday; d += 1) {
            TotalDay memory _totalDay = totalDay[_vid][d];
            if (_totalDay.weight > 0) {
                weightedAverage = _totalDay.amount.div(_totalDay.weight);
                reward += rewardDay.mul(weightedAverage.mul(userWeight).mul(1e9).div(_totalDay.amount)).div(1e18);
                // console.log("Dia %s", d);
                // console.log("_totalDay.amount %s, _totalDay.weight %s, rewardDay %s",_totalDay.amount, _totalDay.weight, rewardDay.div(1e9));
                // console.log(" weightedAverage %s, userWeight %s, reward %s", weightedAverage, userWeight, reward);
                // console.log(" ");
            }
        }
        return reward;
    }
}
