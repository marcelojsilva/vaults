const { expect } = require('chai');
// const {utils} = require('ethers');
// const {isAddress} = require('ethers/lib/utils');
// const { BigNumber } = require("ethereum-waffle");

describe('Prepare Vault', () => {
    let Token, token, vault, Vault, owner, addr1, addr2;
    let userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime
    const typeToken = 1;
    const typeLP = 2;

    beforeEach(async () => {
        Token = await ethers.getContractFactory('NoFeeToken');
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        token = await Token.deploy(
            'test', 'TESTX', ethers.utils.parseUnits("1000000", "gwei")
        );

        Vault = await ethers.getContractFactory('Vault');
        vault = await Vault.deploy(0);

        const bag = ethers.utils.parseUnits("250000", "gwei")

        token.transfer(addr1.address, bag);
        token.transfer(addr2.address, bag);
    });


    it('Create Vault', async () => {
        let totalRewards = ethers.utils.parseUnits("1000", "gwei");
        let vaultTotalDays = 100;
        const oneDay = 60 * 60 * 24;
        let rewardsPerDay = totalRewards / vaultTotalDays

        await token.approve(vault.address, totalRewards);

        await vault.createVault(
            token.address,
            false,
            vaultTotalDays,
            totalRewards
        );

        describe('Validate rewards - Formula: ((block.number - user.lastReawardBlock) * pointsPerBlock * user.amount / vault.userAmount)', () => {
            const userBag = ethers.utils.parseUnits("100", "gwei");

            it('Validate zero rewards after first deposit user', async () => {
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    1632958826,
                    userBag,
                );

                [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserVaultInfo(0, addr1.address);
                expect(parseInt(await userReward)).to.be.equal(0);
            });

            let user1Reward = 0;
            let accUser1 = 0;
            it('Validate rewards after 1 day and new deposit of the user1', async () => {

                await ethers.provider.send('evm_increaseTime', [oneDay]);
                await ethers.provider.send("evm_mine");
                // console.log("startTimestamp %s", (await ethers.provider.getBlock()).timestamp);

                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    1632958826,
                    userBag,
                );
                accUser1 = accUser1 + userBag;

                [userAmount, userLastReawardTime, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserVaultInfo(0, addr1.address);
                userReward = parseInt(parseInt(await userReward) / 100000000)
                user1Reward = userReward;
                expect(user1Reward).to.be.equal(rewardsPerDay / 100000000);
            });

            it('Validate rewards after 3 days and new deposit of the user1', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 3]);
                await ethers.provider.send("evm_mine");
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    1632958826,
                    userBag,
                );
                accUser1 = accUser1 + userBag;

                [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserVaultInfo(0, addr1.address);
                userReward = parseInt(parseInt(await userReward) / 100000000);
                expect(userReward).to.be.equal(user1Reward + rewardsPerDay * 3 / 100000000);
            });

            it('Validate zero rewards after 1 block and first deposit of the user2', async () => {
                await ethers.provider.send('evm_mine');
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    1632958826,
                    userBag,
                );

                [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserVaultInfo(0, addr2.address);
                expect(parseInt(await userReward)).to.be.equal(0);
            });
        });
    });
});