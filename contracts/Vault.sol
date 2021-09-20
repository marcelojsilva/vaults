// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;

    uint256 public vaultId = 0;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    VaultInfo[] public vaultInfo;

    // Info of each pool.
    struct VaultInfo {
        uint256 vid;
        IERC20 token;
        uint256 vaultRewardsPerWeight;
        uint256 vaultTokenReserve;
        uint256 startBlockTime;           // Address of LP token contract.
        uint256 endBlockTime;           // Address of LP token contract.
        bool isLpVault;           // Address of LP token contract.
        bool created;           // Address of LP token contract.
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
            isLpVault : _isLp,
            created: true
        }));

        vaultId = vaultId++;

        //remover taxa
        require(_token.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");
    }

    function getVault(uint256 _vid) public view returns (uint256, IERC20, uint256, uint256, uint256){
        VaultInfo storage vault = vaultInfo[_vid];
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

    function deposit(uint256 _pid, uint256 _lockTime, uint256 _amount) public {
        require(vaultInfo[_pid].created == true, "Vault not found");
        VaultInfo storage pool = vaultInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        if(user.amount == 0) {
            user.rewardDebt = 0;
        }

        require(pool.token.transferFrom(address(msg.sender), address(this), _amount));
        user.amount = user.amount + _amount;
    }

    function withdraw(uint256 _pid, uint256 _amount) public {
        require(_amount > 0, 'amount 0');
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not enough");

        VaultInfo storage pool = vaultInfo[_pid];

        //require(pool.transfer((address(msg.sender), _amout)));
    }
}