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
        uint256 lastReawardBlock;
        uint256 reward;
        uint256 rewardWithdraw;
        uint256 lockTime;
    }

    VaultInfo[] public vaultInfo;

    // Info of each pool.
    struct VaultInfo {
        IERC20 token;
        uint256 amountReward;
        uint256 vaultTokenTax;
        uint256 startBlockTime;           
        uint256 blockDays;
        uint256 totalBlocks;
        uint256 userCount;  
        uint256 userAmount;         
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

    function createVault(IERC20 _token, bool _isLp, uint256 _blockDays, uint256 _amount) public {
        require(_token.balanceOf(msg.sender) >= _amount, "User has no tokens");
        
        //TODO validate tax free for babydoge 
        uint256 _amountReserve = _amount / 100 * 98;
        uint256 _tax = _amount / 100 * 2;
        // console.log("block.number: %s + days: %s", block.number, block + _blockDays);

        vaultInfo.push(VaultInfo({
            token : _token,
            amountReward : _amountReserve,
            vaultTokenTax : _tax,
            startBlockTime : block.timestamp,
            blockDays : _blockDays,
            totalBlocks: _blockDays, //TODO usando como total de blocos para teste
            userCount: 0,
            userAmount: 0,
            isLpVault : _isLp,
            created: true,
            paused: false,
            closed: false
        }));

        require(_token.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");
    }

    function getUserVaultInfo(uint256 _vid, address _user) public view returns (uint256, uint256, uint256, uint256, uint256){
        UserInfo memory user = userInfo[_vid][_user];
        return (
            user.amount,
            user.lastReawardBlock,
            user.reward,
            user.rewardWithdraw,
            user.lockTime
        );
    }
    
    // function getVault(uint256 _vid) public view returns (IERC20, uint256, uint256, uint256, uint256, uint256){
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

    function pendingReward(uint256 _vid, address _user) public {

    }

    function updateVault() public {
        // VaultInfo storage vault = vaultInfo[_vid];
        // if (block.number <= vault.lastRewardBlock) {
        //     return;
        // }
        // uint256 lpSupply = vault.lpToken.balanceOf(address(this));
        // if (lpSupply == 0) {
        //     vault.lastRewardBlock = block.number;
        //     return;
        // }
        // uint256 multiplier = block.number - vault.lastRewardBlock;
        // uint256 cakeReward = multiplier.mul(cakePerBlock).mul(vault.allocPoint).div(totalAllocPoint);
        // cake.mint(devaddr, cakeReward.div(10));
        // cake.mint(address(syrup), cakeReward);
        // vault.accCakePerShare = vault.accCakePerShare.add(cakeReward.mul(1e12).div(lpSupply));
        // vault.lastRewardBlock = block.number;
    }

    function deposit(uint256 _vid, uint256 _lockTime, uint256 _amount) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.token.balanceOf(msg.sender) >= _amount);
        require(vault.created == true, "Vault not found");
        require(vault.closed == false, "Vault closed");
        require(vault.paused == false, "Vault paused");

        UserInfo storage user = userInfo[_vid][msg.sender];

        require(vault.token.transferFrom(address(msg.sender), address(this), _amount));

        uint256 pointsPerBlock = vault.amountReward / vault.totalBlocks;
        // console.log("Before: pointsPerBlock     %s, vault.userAmount    %s, user.reward             %s", pointsPerBlock, vault.userAmount, user.reward);
        // console.log("Before: vault.amountReward %s, user.amount         %s, user.lastReawardBlock   %s", vault.amountReward, user.amount, user.lastReawardBlock);
        vault.userAmount = vault.userAmount + _amount;
        if(user.amount == 0){
            vault.userCount = vault.userCount + 1;
        } else {
            user.reward = user.reward + ((block.number - user.lastReawardBlock) * pointsPerBlock * user.amount / vault.userAmount);
        }
        user.lastReawardBlock = block.number;
        user.amount = user.amount + _amount;
        user.lockTime = _lockTime; // TODO validar como ficará locktime quando houver segundo depósito, valerá o último?
        
        // console.log("After:  pointsPerBlock     %s, vault.userAmount    %s, user.reward             %s", pointsPerBlock, vault.userAmount, user.reward);
        // console.log("After:  vault.amountReward %s, user.amount         %s, user.lastReawardBlock   %s", vault.amountReward, user.amount, user.lastReawardBlock);

        emit Deposit(msg.sender, _vid, _amount);
    }

    function withdraw(uint256 _vid) public {
        VaultInfo storage vault = vaultInfo[_vid];
        require(vault.created == true, "Vault not found");
        require(vault.paused == false, "Vault paused");

        // UserInfo storage user = userInfo[_vid][msg.sender];
        //require(user.lockTime >= vault.endBlockTime, "Vault paused");

        // uint256 total = user.amount + user.rewardDebt;

        // require(vault.token.transfer(address(msg.sender), total));

        // console.log(vault.userCount);

        vault.userCount = vault.userCount - 1;

        delete userInfo[_vid][msg.sender];
    }

}