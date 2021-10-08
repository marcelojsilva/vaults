const { expect } = require('chai');

describe('Prepare Vault', () => {
    let Token, token, vault, Vault, owner, addr1, addr2;
    let userAmount, userWeight, userReward1, userReward2, userReward3, userRewardWithdraw, userLockTime
    const typeToken = 1;
    const typeLP = 2;
    const oneDay = 60 * 60 * 24;
    const gwei = ethers.utils.parseUnits("1", "gwei")
    const supply = 1000000;
    const bag = 250000 * gwei;
    const totalRewards = 1000 * gwei;

    beforeEach(async () => {
        Token = await ethers.getContractFactory('NoFeeToken');
        [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
        token = await Token.deploy(
            'test', 'TESTX', supply*gwei
        );
        Vault = await ethers.getContractFactory('Vault');
        //Pass BabyDoge´s address token on deploy of the Vault
        vault = await Vault.deploy(token.address, 2);

        token.transfer(addr1.address, bag);
        token.transfer(addr2.address, bag);
        token.transfer(addr3.address, bag);
    });


    it('Create Vault for 10 days', async () => {

        let vaultTotalDays = 10;

        await token.approve(vault.address, totalRewards);

        await vault.createVault(
            token.address,
            token.address,
            false,
            vaultTotalDays,
            totalRewards
        );

        describe('Valid deposits', () => {
            it('Validate non zero deposit', async () => {
                await token.connect(addr1).approve(vault.address, 0);
                await expect(vault.connect(addr1).deposit(
                    0,
                    0,
                    0,
                )).to.be.revertedWith('Deposit must be greater than zero');
            });
        });

        describe('Validate rewards', () => {
            const userBag = 100 * gwei;

            it('Validate zero rewards after first deposit user', async () => {
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    0,
                    userBag,
                );

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr1.address);
                expect(parseInt(userReward)).to.be.equal(0);
            });

            it('Whithdraw after 7 day of user2 with weight 1.7 and user3 with weight 1.3', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay]);
                await ethers.provider.send("evm_mine");
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    7,
                    userBag,
                );
                await token.connect(addr3).approve(vault.address, userBag);
                await vault.connect(addr3).deposit(
                    0,
                    3,
                    userBag,
                );

                await ethers.provider.send('evm_increaseTime', [oneDay * 7]);
                await ethers.provider.send("evm_mine");

                await vault.connect(addr2).withdraw(0);
                await vault.connect(addr3).withdraw(0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr2.address);
                userReward2 = parseInt(userReward / gwei);
                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr3.address);
                userReward3 = parseInt(userReward / gwei);

                expect(userReward2).to.be.equal(297);
                expect(userReward3).to.be.equal(227);
            });

            it('Whithdraw after 1 day of user2 with weight 1.1 and user3 with weight 1', async () => {
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    0,
                    userBag,
                );
                await token.connect(addr2).approve(vault.address, userBag);
                await vault.connect(addr2).deposit(
                    0,
                    1,
                    userBag,
                );
                await token.connect(addr3).approve(vault.address, userBag);
                await vault.connect(addr3).deposit(
                    0,
                    0,
                    userBag,
                );

                await ethers.provider.send('evm_increaseTime', [oneDay * 1]);
                await ethers.provider.send("evm_mine");

                await vault.connect(addr2).withdraw(0);
                await vault.connect(addr3).withdraw(0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr2.address);
                userReward2 = parseInt(userReward / gwei);
                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr3.address);
                userReward3 = parseInt(userReward / gwei);

                expect(userReward2).to.be.equal(297+35);
                expect(userReward3).to.be.equal(227+32);
            });

            it('Withdrawal of the user1 of all 10 days invested with weight 1', async () => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 2]);
                await ethers.provider.send("evm_mine");
                await vault.connect(addr1).withdraw(0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                    await vault.getUserInfo(0, addr1.address);
                userReward1 = parseInt(userReward / gwei);
                
                expect(userReward1).to.be.equal(407);
            });

            it('Total rewards achieved', async () => {
                userReward = (userReward1 + userReward2 + userReward3) * gwei;
                expect(userReward).to.be.lessThanOrEqual(totalRewards);
                expect(userReward).to.be.greaterThanOrEqual(parseInt(totalRewards * 0.9));
            });
        });
    });
});