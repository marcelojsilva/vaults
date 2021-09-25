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

    uint public vaultId = 0;
    uint public taxForNonBabyDogeCoin = 0;

    struct UserInfo {
        uint amount;
        uint lastRewardTime;
        uint rewardDebt;
        uint rewardWithdraw;
        uint lockTime;
    }

    VaultInfo[] public vaultInfo;

    struct VaultInfo {
        IERC20 token;
        uint amountReward;
        uint vaultTokenTax;
        uint startBlockTime;           
        uint endTimeBlockTime;
        uint userCount;  
        uint usersAmount;         
        bool isLpVault;           
        bool created;           
        bool paused;           
        bool closed;           
    }

    mapping(uint => mapping(address => UserInfo)) public userInfo;

    // addresses list
    uint[] public addressList;

    //address public babydogeAddr = 0xc748673057861a797275cd8a068abb95a902e8de;

    event Deposit(address indexed user, uint indexed pid, uint amount);
    event Withdraw(address indexed user, uint indexed pid, uint amount);

    constructor(
        uint _taxForNonBabyDogeCoin 
    )
    {
        taxForNonBabyDogeCoin = _taxForNonBabyDogeCoin;
    }
    function createVault(IERC20 _token, bool _isLp, uint _blockDays, uint _amount) public {
        require(_token.balanceOf(msg.sender) >= _amount, "User has no tokens");
        //TODO validate tax free for babydoge 
        uint _amountReserve = _amount / 100 * (100 - taxForNonBabyDogeCoin);
        uint _tax = _amount / 100 * taxForNonBabyDogeCoin;
        vaultInfo.push(VaultInfo({
            token : _token,
            amountReward : _amountReserve,
            vaultTokenTax : _tax,
            startBlockTime : block.timestamp,
            endTimeBlockTime: block.timestamp.add(_blockDays * 24 * 60 *60), 
            userCount: 0,
            usersAmount: 0,
            isLpVault : _isLp,
            created: true,
            paused: false,
            closed: false
        }));

        require(_token.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");
    }

    function getUserVaultInfo(uint _vid, address _user) public view returns (uint, uint, uint, uint, uint){
        UserInfo memory user = userInfo[_vid][_user];
        return (
            user.amount,
            user.lastRewardTime,
            user.rewardDebt,
            user.rewardWithdraw,
            user.lockTime
        );
    }
    
    // function getVault(uint _vid) public view returns (IERC20, uint, uint, uint, uint, uint){
    //     VaultInfo memory vault = vaultInfo[_vid];
    //     return (
    //         vault.token,
    //         vault.amountReward,
    //         vault.vaultTokenTax,
    //         vault.blockDays,
    //         vault.startBlockTime,
    //         vault.endBlockTime
    //     );
    // }

    function pendingReward(uint _vid, address _user) public {

    }

    function rewardCalculate(uint _vid) internal view returns (uint)
    {
        UserInfo memory user = userInfo[_vid][msg.sender];
        uint lastRewardTime = user.lastRewardTime;
        if (block.timestamp <= lastRewardTime) {
            return 0;
        }
        VaultInfo memory vault = vaultInfo[_vid];
        if (vault.usersAmount == 0) {
            return 0;
        }
        if (vault.usersAmount == 0) {
            return 0;
        }
        uint totalSeconds = vault.endTimeBlockTime.sub(vault.startBlockTime);
        uint pointsPerSecond = vault.amountReward.mul(1e12).div(totalSeconds);
        uint multiplier = block.timestamp.sub(lastRewardTime);
        uint reward = multiplier.mul(pointsPerSecond).mul(user.amount).div(vault.usersAmount).div(1e12);
        return reward;
    }

    function deposit(uint _vid, uint _lockTime, uint value) external returns (bool) {
        require(value > 0, 'Deposit must be greater than zero');
        VaultInfo storage vault = vaultInfo[_vid];
        // require(vault.token.balanceOf(msg.sender) >= _amount); //TODO qual necessidade desta validação?
        require(vault.created == true, "Vault not found");
        require(vault.closed == false, "Vault closed");
        require(vault.paused == false, "Vault paused");
        // require(block.timestamp >= vault.endTimeBlockTime, "Vault not started");
        // require(block.timestamp <= vault.endTimeBlockTime, "Vault finiched");
        require(vault.token.transferFrom(address(msg.sender), address(this), value));

        UserInfo storage user = userInfo[_vid][msg.sender];

        uint reward = rewardCalculate(_vid);
        if (user.amount == 0) {
            user.lockTime = _lockTime;
        }
        vault.usersAmount = vault.usersAmount.add(value);
        user.amount = user.amount.add(value);
        user.rewardDebt = user.rewardDebt.add(reward);
        user.lastRewardTime = block.timestamp;

        // console.log("User After:\n user.amount\n %s\n user.rewardDebt\n %s\n user.lastRewardTime\n %s\n", user.amount, user.rewardDebt, user.lastRewardTime);
        // console.log("Vault After:\n vault.amountReward\n %s\n vault.startBlockTime\n %s\n vault.usersAmount\n %s\n", vault.amountReward, vault.startBlockTime, vault.usersAmount);

        emit Deposit(msg.sender, _vid, value);
        return true;
    }


    function withdraw(uint _vid) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.created == true, "Vault not found");
        require(vault.paused == false, "Vault paused");
        UserInfo memory user = userInfo[_vid][msg.sender];
        require(user.lockTime >= block.timestamp, "User in lock time");
        // UserInfo storage user = userInfo[_vid][msg.sender];
        // require(user.lockTime >= vault.startBlockTime.add(vault.blockDays), "User in lockTime");

        // uint total = user.amount + user.rewardDebt;

        // require(vault.token.transfer(address(msg.sender), total));

        // console.log(vault.userCount);

        vault.userCount = vault.userCount - 1;

        delete userInfo[_vid][msg.sender];
    }

}