// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    uint256 public vaultId = 0;

    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lockTime;
    }

    VaultInfo[] public vaultInfo;

    // Info of each pool.
    struct VaultInfo {
        uint256 vid;
        IERC20 token;
        uint256 vaultRewardsPerWeight;
        uint256 vaultTokenReserve;
        uint256 startBlockTime;           
        uint256 endBlockTime;           
        uint256 userCount;           
        bool isLpVault;           
        bool created;           
        bool paused;           
        bool closed;           
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // addresses list
    uint256[] public addressList;

    //address public babydogeAddr = 0xc748673057861a797275cd8a068abb95a902e8de;

    //uint256 public startBlock;
    //uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);

    function createVault(IERC20 _token, bool _isLp, uint256 _amount) public {
        require(_token.balanceOf(msg.sender) >= _amount, "User has no tokens");

        vaultInfo.push(VaultInfo({
            vid : vaultId,
            token : _token,
            vaultRewardsPerWeight : 1,
            vaultTokenReserve : _amount,
            startBlockTime : block.timestamp,
            endBlockTime : 25 days,
            userCount: 0,
            isLpVault : _isLp,
            created: true,
            paused: false,
            closed: false
        }));

        vaultId = vaultId++;

        //remover taxa
        require(_token.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");
    }

    function getUserVaultInfo(uint256 _vid, address _user) public view returns (uint256, uint256, uint256){
        UserInfo memory user = userInfo[_vid][_user];
        return (
            user.amount,
            user.rewardDebt,
            user.lockTime
        );
    }

    function getVault(uint256 _vid) public view returns (uint256, IERC20, uint256, uint256, uint256){
        VaultInfo memory vault = vaultInfo[_vid];
        return (
            vault.vid,
            vault.token,
            vault.vaultTokenReserve,
            vault.startBlockTime,
            vault.endBlockTime
        );
    }

    function pendingReward(uint256 _pid, address _user) public {

    }

    function updateVault() public {

    }

    function deposit(uint256 _vid, uint256 _lockTime, uint256 _amount) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.token.balanceOf(msg.sender) >= _amount);
        require(vault.created == true, "Vault not found");
        require(vault.closed == false, "Vault closed");
        require(vault.paused == false, "Vault paused");

        UserInfo storage user = userInfo[_vid][msg.sender];

        require(vault.token.transferFrom(address(msg.sender), address(this), _amount));

        if(user.amount == 0){
            vault.userCount = vault.userCount + 1;
            user.lockTime = _lockTime;
        }

        user.amount = user.amount + _amount;
    }

    function withdraw(uint256 _vid) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.created == true, "Vault not found");
        require(vault.paused == false, "Vault paused");

        UserInfo storage user = userInfo[_vid][msg.sender];
        //require(user.lockTime >= vault.endBlockTime, "Vault paused");

        uint256 total = user.amount + user.rewardDebt;

        require(vault.token.transfer(address(msg.sender), total));

        console.log(vault.userCount);

        vault.userCount = vault.userCount - 1;

        delete userInfo[_vid][msg.sender];
    }
}