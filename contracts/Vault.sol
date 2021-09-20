// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable{
    using SafeERC20 for IERC20;

    uint256 public vaultId = 0;

    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    enum Type { Token, Lp }

    PoolInfo[] public poolInfo;

    // Info of each pool.
    struct PoolInfo {
        uint256 pid;
        IERC20 token;           // Address of LP token contract.
        uint256 amount;           // Address of LP token contract.
    }

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;

    //address public babydogeAddr = 0xc748673057861a797275cd8a068abb95a902e8de;

    //uint256 public startBlock;
    //uint256 public endBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

   function createPool(IERC20 _token, uint256 _type, uint256 _endBlock, uint256 _amount) public {
       require((_type == 1 || _type == 2), "Invalid type");

       vaultId = vaultId++;

        poolInfo.push(PoolInfo({
            pid: vaultId,
            token: _token,
            amount: _amount
        }));

       //remover taxa
       require(_token.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");
    }

      // Deposit LP tokens to MasterChef for CAKE allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        //controlar novos depositos
        require(pool.token.transferFrom(address(msg.sender), address(this), _amount));
        user.amount = user.amount + _amount;
    }


    //100000

    //511
}