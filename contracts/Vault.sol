// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Vault is Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    uint256 public taxForNonBabyDogeCoin;
    IERC20 public babydoge;

    struct UserInfo {
        uint256 amount;
        uint256 weight;
        uint256 rewardTotal;
        uint256 rewardWithdraw;
        uint256 lockTime;
        uint256 lockDays;
        uint256 lastRewardTimeStamp;
        bool exists;
    }

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    mapping(uint256 => uint256) public vaultKeys;

    struct TotalPeriod {
        uint256 amount;
        uint256 weight;
    }

    mapping(uint256 => mapping(uint256 => TotalPeriod)) public totalDay;
    mapping(uint256 => mapping(uint256 => TotalPeriod)) public totalHour;
    mapping(uint256 => mapping(uint256 => TotalPeriod)) public totalMinute;


    struct VaultToken {
        IERC20 tokenStake;
        IERC20 tokenReward;
        address vaultCreator;
    }

    struct VaultInfo {
        uint256 amountReward;
        uint256 vaultTokenTax;
        uint256 startVault;
        uint256 vaultDays;
        uint256 minLockDays;
        uint256 userCount;
        uint256 usersAmount;
        uint256 usersWeight;
        bool isLpVault;
        bool paused;
        uint256 lastTotalTimeStamp;
    }

    VaultToken[] public vaultToken;
    VaultInfo[] public vaultInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event ClaimRewards(address indexed user, uint256 indexed pid, uint256 amount);
    event SetTaxForNonBabyDogeCoin(uint256 _taxForNonBabyDogeCoin);
    event CreateVault(uint256 key, IERC20 _tokenStake, IERC20 _tokenReward, bool _isLp, uint256 _vaultDays, uint256 _minLockDays, uint256 _amount);

    constructor(IERC20 _babydoge) {
        babydoge = _babydoge;
    }

    function setTaxForNonBabyDogeCoin(uint256 _taxForNonBabyDogeCoin) external onlyOwner {
        require(_taxForNonBabyDogeCoin <= 100, "Tax greater than 100");
        taxForNonBabyDogeCoin = _taxForNonBabyDogeCoin;

        emit SetTaxForNonBabyDogeCoin(_taxForNonBabyDogeCoin);
    }

    function createVault(
        uint256 key,
        IERC20 _tokenStake,
        IERC20 _tokenReward,
        bool _isLp,
        uint256 _vaultDays,
        uint256 _minLockDays,
        uint256 _amount
    ) external returns (uint256) {

        require(vaultKeys[key] == 0, "Vault Key Already used");
        require(_tokenReward.balanceOf(msg.sender) >= _amount, "User has no tokens");
        require(_vaultDays > 0, "Vault days zero");
        require(_minLockDays <= _vaultDays, "Minimum lock days greater then Vault days");

        uint256 tax = 0;

        if (!isBabyDoge(_tokenReward)) {
            tax = taxForNonBabyDogeCoin;
        }

        uint256 _amountReserve = (_amount * (100 - tax) / 100);
        uint256 _tax = (_amount * tax / 100);

        vaultToken.push(
            VaultToken({tokenStake : _tokenStake, tokenReward : _tokenReward, vaultCreator : msg.sender})
        );

        VaultInfo memory vault = VaultInfo({
            amountReward : _amountReserve,
            vaultTokenTax : _tax,
            startVault : block.timestamp,
            vaultDays : _vaultDays,
            minLockDays : _minLockDays,
            userCount : 0,
            usersAmount : 0,
            usersWeight : 0,
            isLpVault : _isLp,
            paused : false,
            lastTotalTimeStamp : block.timestamp
        });

        vaultInfo.push(vault);

        uint256 vaultId = vaultInfo.length - 1;

        vaultKeys[key] = vaultId;

        require(_tokenReward.transferFrom(address(msg.sender), address(this), _amount), "Can't transfer tokens.");


        emit CreateVault(key, _tokenStake, _tokenReward, _isLp, _vaultDays, _minLockDays, _amount);

        return vaultId;
    }

    function getVaultId(uint256 key) external view returns (uint256) {
        return vaultKeys[key];
    }

    function isBabyDoge(IERC20 _token) internal view returns (bool) {
        return address(_token) == address(babydoge);
    }

    function getUserInfo(uint256 _vid, address _user)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    )
    {
        UserInfo memory user = userInfo[_vid][_user];
        return (
        user.amount,
        user.weight,
        user.rewardTotal,
        user.rewardWithdraw,
        user.lockTime
        );
    }

    function getVaultToken(uint256 _vid) external view returns (IERC20, IERC20) {
        VaultToken memory vaultT = vaultToken[_vid];
        return (vaultT.tokenStake, vaultT.tokenReward);
    }

    function getVaultInfo(uint256 _vid)
    external
    view
    returns (
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256,
        IERC20,
        IERC20
    )
    {
        VaultInfo memory vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        uint256 endDay = endVaultDay(_vid);
        return (
        vault.amountReward,
        vault.vaultTokenTax,
        vault.vaultDays,
        vault.minLockDays,
        vault.startVault,
        endDay,
        vault.userCount,
        vault.usersAmount,
        vault.usersWeight,
        vaultT.tokenStake,
        vaultT.tokenReward
        );
    }

    function endVaultDay(uint256 _vid) internal view returns (uint256) {
        VaultInfo memory vault = vaultInfo[_vid];
        return vault.startVault.add(vault.vaultDays * 24 * 60 * 60);
    }

    function today() internal view returns (uint256) {
        return block.timestamp.div(1 days);
    }

    function currentHour() internal view returns (uint256) {
        return block.timestamp.div(1 hours);
    }

    function currentMinute() internal view returns (uint256) {
        return block.timestamp.div(1 minutes);
    }

    function yesterday(uint256 _vid) internal view returns (uint256) {
        uint256 endVault = endVaultDay(_vid);
        return
        block.timestamp > endVault
        ? endVault.div(1 days).sub(1)
        : block.timestamp.div(1 days).sub(1);
    }

    function lastHour(uint256 _vid) internal view returns (uint256) {
        uint256 endVault = endVaultDay(_vid);
        return
        block.timestamp > endVault
        ? endVault.div(1 hours).sub(1)
        : block.timestamp.div(1 hours).sub(1);
    }

    function lastMinute(uint256 _vid) internal view returns (uint256) {
        uint256 endVault = endVaultDay(_vid);
        return
        block.timestamp > endVault
        ? endVault.div(1 minutes).sub(1)
        : block.timestamp.div(1 minutes).sub(1);
    }

    function sync(uint256 _vid) internal {
        VaultInfo memory vault = vaultInfo[_vid];
        uint256 start;
        uint256 end;
        uint256 _amountHour;
        uint256 _weightHour;
        
        if (vault.lastTotalTimeStamp.div(1 minutes) >= lastMinute(_vid).add(1)) {
            return;
        }
        
        TotalPeriod memory _lastTotalMinute0 = totalMinute[_vid][vault.lastTotalTimeStamp.div(1 minutes)];

        //**Calculate average total hour of lastTotalTimeStamp */

        // Sum minutes from last exactly hour to last minute
        start = vault.lastTotalTimeStamp.div(1 hours).mul(60);
        end = vault.lastTotalTimeStamp.div(1 minutes);
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod memory _lastTotalMinute1 = totalMinute[_vid][d];
            _amountHour += _lastTotalMinute1.amount;
            _weightHour += _lastTotalMinute1.weight;
        }
        //Calc minutes to exact hour
        start = vault.lastTotalTimeStamp.div(1 minutes);
        end = vault.lastTotalTimeStamp.div(1 hours).add(1).mul(60);
        if (lastMinute(_vid).add(1) < end) {
            end = lastMinute(_vid).add(1);
        }
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod storage _lastTotalMinute2 = totalMinute[_vid][d];
            _lastTotalMinute2.amount = _lastTotalMinute0.amount;
            _lastTotalMinute2.weight = _lastTotalMinute0.weight;
            _amountHour += _lastTotalMinute0.amount;
            _weightHour += _lastTotalMinute0.weight;
        }
        // Calc average hour
        TotalPeriod storage _lastTotalHour1 = totalHour[_vid][vault.lastTotalTimeStamp.div(1 hours)];
        _lastTotalHour1.amount = _amountHour.div(60);
        _lastTotalHour1.weight = _weightHour.div(60);

        //** Calculate average total day of lastTotalTimeStamp */

        //Calc hours from next hour to midnight
        start = vault.lastTotalTimeStamp.div(1 hours).add(1);
        end = block.timestamp.div(1 hours);
        if (lastHour(_vid).add(1) < end) {
            end = lastHour(_vid).add(1);
        }
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod storage _lastTotalHour2 = totalHour[_vid][d];
            _lastTotalHour2.amount = _lastTotalMinute0.amount;
            _lastTotalHour2.weight = _lastTotalMinute0.weight;
        }

        // Sync lastTotalTimeStamp from last hour to next minutes until last minute
        start = block.timestamp.div(1 hours).mul(60);
        if (start < vault.lastTotalTimeStamp.div(1 minutes)) {
            start = vault.lastTotalTimeStamp.div(1 minutes);
        }
        end = block.timestamp.div(1 minutes);
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod storage _lastTotalMinute3 = totalMinute[_vid][d];
            _lastTotalMinute3.amount = _lastTotalMinute0.amount;
            _lastTotalMinute3.weight = _lastTotalMinute0.weight;
        }

    }

    function deposit(uint256 _vid, uint256 _lockDays, uint256 value) external returns (bool) {
        require(value > 0, "Deposit must be greater than zero");
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        uint256 endVault = endVaultDay(_vid);
        require(!vault.paused, "Vault paused");
        require(block.timestamp >= vault.startVault, "Vault not started");
        require(block.timestamp <= endVault, "Vault finished");
        require(_lockDays >= vault.minLockDays, "Locked days of the user is less than minimum lock day's Vault");
        require(_lockDays <= vault.vaultDays, "Locked days of the user is greater than lock day's Vault");
        require(
            vaultT.tokenStake.transferFrom(
                address(msg.sender),
                address(this),
                value
            )
        );

        UserInfo storage user = userInfo[_vid][msg.sender];
        uint256 stakeWeight = 0;
        if (!user.exists) {
            user.exists = true;
            uint256 _lockTime = block.timestamp.add(_lockDays * 24 * 60 * 60);
            _lockTime = _lockTime > endVault ? endVault : _lockTime;
            user.lockTime = _lockTime;
            user.lockDays = _lockDays;
            user.lastRewardTimeStamp = block.timestamp;
            vault.userCount += 1;
            stakeWeight = (user.lockDays.mul(1e9)).div(vault.vaultDays).add(
                1e9
            );
            user.weight = stakeWeight;
        } else {
            //New deposits of the same user with the same weight as the first one
            stakeWeight = 0;
        }

        user.amount += value;

        sync(_vid);

        vault.lastTotalTimeStamp = block.timestamp;
        vault.usersAmount += value;
        vault.usersWeight += stakeWeight;

        TotalPeriod storage _totalHour = totalHour[_vid][currentHour()];
        _totalHour.amount = vault.usersAmount;
        _totalHour.weight = vault.usersWeight;

        TotalPeriod storage _totalMinute = totalMinute[_vid][currentMinute()];
        _totalMinute.amount = vault.usersAmount;
        _totalMinute.weight = vault.usersWeight;

        emit Deposit(address(msg.sender), _vid, value);

        return true;
    }

    function claimRewards(uint256 _vid) external {
        VaultToken memory vaultT = vaultToken[_vid];
        VaultInfo memory vault = vaultInfo[_vid];
        require(!vault.paused, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];

        sync(_vid);

        uint256 userReward = calcRewardsUser(_vid, msg.sender);

        user.lastRewardTimeStamp = block.timestamp;
        user.rewardTotal += userReward;
        uint256 remainingReward = user.rewardTotal.sub(user.rewardWithdraw);

        require(remainingReward > 0, "No value to claim");

        require(
            vaultT.tokenReward.transfer(address(msg.sender), remainingReward)
        );

        user.rewardWithdraw += remainingReward;

        emit ClaimRewards(address(msg.sender), _vid, remainingReward);

    }

    function withdraw(uint256 _vid, uint256 amount) external {
        require(amount > 0, "Withdraw amount zero");
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        require(!vault.paused, "Vault paused");
        UserInfo storage user = userInfo[_vid][msg.sender];
        require(user.lockTime <= block.timestamp, "User in lock time");
        require(user.amount >= amount, "Withdraw amount greater than user amount");

        sync(_vid);

        uint256 userReward = calcRewardsUser(_vid, msg.sender);

        user.lastRewardTimeStamp = block.timestamp;
        user.rewardTotal += userReward;

        require(vaultT.tokenStake.transfer(address(msg.sender), amount));

        user.amount -= amount;
        vault.usersAmount -= amount;
        vault.lastTotalTimeStamp = user.lastRewardTimeStamp;
        if (user.amount == 0) {
            user.exists = false;
            vault.userCount = vault.userCount - 1;
            vault.usersWeight -= user.weight;
            user.weight = 0;
        }


        TotalPeriod storage _totalHour = totalHour[_vid][currentHour()];
        _totalHour.amount = vault.usersAmount;
        _totalHour.weight = vault.usersWeight;

        TotalPeriod storage _totalMinute = totalMinute[_vid][currentMinute()];
        _totalMinute.amount = vault.usersAmount;
        _totalMinute.weight = vault.usersWeight;

        emit Withdraw(address(msg.sender), _vid, amount);

    }

    function withdrawTax(uint256 _vid) external onlyOwner {
        VaultInfo storage vault = vaultInfo[_vid];
        VaultToken memory vaultT = vaultToken[_vid];
        require(vault.vaultTokenTax > 0, "Vault without token tax left");
        require(
            vaultT.tokenReward.transfer(owner(), vault.vaultTokenTax),
            "Can't transfer tax to owner"
        );
        vault.vaultTokenTax = 0;
    }


    function calcRewardsUser(uint256 _vid, address _user) public view returns (uint256) {
        UserInfo memory user = userInfo[_vid][_user];
        VaultInfo memory vault = vaultInfo[_vid];
        uint256 rewardDay = vault.amountReward.div(vault.vaultDays);
        uint256 rewardHour = rewardDay.div(24);
        uint256 rewardMinute = rewardHour.div(60);
        uint256 reward = 0;
        uint256 start;
        uint256 end;

        //Calc minutes to exact hour
        start = user.lastRewardTimeStamp.div(1 minutes);
        end = user.lastRewardTimeStamp.div(1 hours).add(1).mul(60);
        if (lastMinute(_vid).add(1) < end) {
            end = lastMinute(_vid).add(1);
        }
        reward = CalcRewardMinute(_vid, start, end, rewardMinute, user.weight);

        //Calc hours to midnight 
        start = user.lastRewardTimeStamp.div(1 hours).add(1);
        end = block.timestamp.div(1 hours);
        if (lastHour(_vid).add(1) < end) {
            end = lastHour(_vid).add(1);
        }
        reward += CalcRewardHour(_vid, start, end, rewardHour, user.weight);

        start = block.timestamp.div(1 hours).mul(60);
        end = block.timestamp.div(1 minutes);
        if (lastMinute(_vid).add(1) < end) {
            end = lastMinute(_vid).add(1);
        }
        reward += CalcRewardMinute(_vid, start, end, rewardMinute, user.weight);

        return reward;
    }

    function CalcRewardDay(uint256 _vid, uint256 start, uint256 end, uint256 rewardDay, uint256 userWeight) internal view returns (uint256) {
        uint256 weightedAverage = 0;
        uint256 reward = 0;
        uint256 r;
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod memory _totalDay = totalDay[_vid][d];
            r = 0;
            if (_totalDay.weight > 0) {
                weightedAverage = _totalDay.amount.div(_totalDay.weight);
                r = rewardDay.mul(weightedAverage.mul(userWeight)) / _totalDay.amount;
                reward += r;
            }
        }
        return reward;
    }

    function CalcRewardHour(uint256 _vid, uint256 start, uint256 end, uint256 rewardHour, uint256 userWeight) internal view returns (uint256) {
        uint256 weightedAverage = 0;
        uint256 reward = 0;
        uint256 r;
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod memory _totalHour = totalHour[_vid][d];
            r = 0;
            if (_totalHour.weight > 0) {
                weightedAverage = _totalHour.amount.div(_totalHour.weight);
                r = rewardHour.mul(weightedAverage.mul(userWeight)) / _totalHour.amount;
                reward += r;
            }
        }
        return reward;
    }

    function CalcRewardMinute(uint256 _vid, uint256 start, uint256 end, uint256 rewardMinute, uint256 userWeight) internal view returns (uint256) {
        uint256 weightedAverage = 0;
        uint256 reward = 0;
        uint256 r;
        for (uint256 d = start; d < end; d += 1) {
            TotalPeriod memory _totalMinute = totalMinute[_vid][d];
            r = 0;
            if (_totalMinute.weight > 0) {
                weightedAverage = _totalMinute.amount.div(_totalMinute.weight);
                r = rewardMinute.mul(weightedAverage.mul(userWeight)) / _totalMinute.amount;
                reward += r;
            }
        }
        return reward;
    }
}