const { expect } = require('chai');

describe('Prepare Vault', () => {
    let Token, token, vault, Vault, owner, addr1, addr2;
    let userAmount, userWeight, userReward, userRewardWithdraw, userLockTime
    const typeToken = 1;
    const typeLP = 2;
    const oneDay = 60 * 60 * 24;

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
        let vaultTotalDays = 30;
        let rewardsPerDay = totalRewards / vaultTotalDays
        
        await token.approve(vault.address, totalRewards);
        
        await vault.createVault(
            token.address,
            false,
            vaultTotalDays,
            totalRewards
        );

        describe('Validate rewards', () => {
            const userBag = ethers.utils.parseUnits("100", "gwei");

            it('Validate zero rewards after first deposit user', async () => {
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    29,
                    userBag,
                );

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr1.address);
                expect(parseInt(userReward)).to.be.equal(0);
            });

            let user1RewardDay1 = 0;
            let user1RewardDay3 = 0;
            let accUser1 = 0;
            it('First user1 deposit after 5 days with weight 2', async () => {

                await ethers.provider.send('evm_increaseTime', [oneDay * 5]);
                await ethers.provider.send("evm_mine");
                // console.log("startTimestamp %s", (await ethers.provider.getBlock()).timestamp);

                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    29,
                    userBag,
                );
                accUser1 = accUser1 + userBag;

                totalDay = await vault.totalDay(0,18899);
                // console.log(String(totalDay));

                await vault.syncDays(0);
                // let userReward = await vault.calcRewardsUser(0, addr1.address);

                // console.log(parseInt(userReward/100000000));
                // expect(parseInt(userReward/1000000000)).to.be.equal(parseInt(rewardsPerDay * 10 / 1000000000));
            });

            it('Second user1 deposit after 5 days with weight 2', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 5]);
                await ethers.provider.send("evm_mine");
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    30,
                    userBag,
                );
                accUser1 = accUser1 + userBag;

                await vault.syncDays(0);
                // let userReward = await vault.calcRewardsUser(0, addr1.address);
                
                // console.log(parseInt(userReward/100000000));
                // expect(parseInt(userReward/1000000000)).to.be.equal(parseInt(rewardsPerDay * 10 / 1000000000));
            });

            it('First user2 deposit after 5 days with weight 1', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 5]);
                await ethers.provider.send('evm_mine');
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    0,
                    userBag,
                );

                await vault.syncDays(0);
                // let userReward = await vault.calcRewardsUser(0, addr2.address);
                
                // console.log(parseInt(userReward/1000000000));
                // expect(parseInt(userReward/1000000000)).to.be.equal(parseInt(rewardsPerDay * 10 / 1000000000));
            });

            it('Second user2 deposit after 5 days with weight 1', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 5]);
                await ethers.provider.send('evm_mine');
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    0,
                    userBag,
                );

                await vault.syncDays(0);
                // let userReward = await vault.calcRewardsUser(0, addr2.address);
                
                // console.log(parseInt(userReward/1000000000));
                // expect(parseInt(userReward/1000000000)).to.be.equal(parseInt(rewardsPerDay * 10 / 1000000000));
            });

            it('Third user2 deposit after 5 days with weight 1', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 5]);
                await ethers.provider.send('evm_mine');
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    0,
                    userBag,
                );

                await vault.syncDays(0);
                // let userReward = await vault.calcRewardsUser(0, addr2.address);
                
                // console.log(parseInt(userReward/1000000000));
                // expect(parseInt(userReward/1000000000)).to.be.equal(parseInt(rewardsPerDay * 10 / 1000000000));
            });

            it('Validate rewards on the 29th day of the vault, after withdraw', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay*4]);
                await ethers.provider.send("evm_mine");
                
                await vault.syncDays(0);

                await vault.connect(addr1).withdraw(0);
                await vault.connect(addr2).withdraw(0);
                
                [userAmount, userWeight, userReward1, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr1.address);
                
                [userAmount, userWeight, userReward2, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr2.address);
                
                // console.log(parseInt(userReward1));
                // console.log(parseInt(userReward2));
                expect(userReward1).to.be.equal(719);
                expect(userReward2).to.be.equal(224);
            });

            // it('Validate zero rewards after 1 block and first deposit of the user2', async () => {
            //     await ethers.provider.send('evm_mine');
            //     await token.connect(addr2).approve(vault.address, userBag);
            //     await vault.connect(addr2).deposit(
            //         0,
            //         timestamp + (60*60*24)*30, //atual + 30 dias,
            //         userBag,
            //     );

            //     [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
            //         await vault.getUserInfo(0, addr2.address);
            //     expect(parseInt(await userReward)).to.be.equal(0);
            // });
        });
    });
});