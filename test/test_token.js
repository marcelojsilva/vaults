const { expect } = require('chai');

describe('Prepare Vault', () => {
    let Token, token, vaults, VaultContract, owner, addr1, addr2;
    let userAmount, userWeight, userReward1, userReward2, userReward3, userRewardWithdraw, userLockTime
    const oneDay = 60 * 60 * 24;
    const gwei = ethers.utils.parseUnits("1", "gwei")
    const supply = 1000000;
    const bag = 250000 * gwei;
    const totalVault0Rewards = 1000 * gwei;
    const totalVault1Rewards = 100000 * gwei;
    const vault0 = 0;
    const vault1 = 1;

    beforeEach(async() => {
        Token = await ethers.getContractFactory('NoFeeToken');
        [owner, addr1, addr2, addr3, ...addrs] = await ethers.getSigners();
        token = await Token.deploy(
            'test', 'TESTX', supply * gwei
        );
        VaultContract = await ethers.getContractFactory('Vault');
        //Pass BabyDoge´s address token on deploy of the Vault
        vaults = await VaultContract.deploy(token.address, 2);

        token.transfer(addr1.address, bag);
        token.transfer(addr2.address, bag);
        token.transfer(addr3.address, bag);
    });


    it('Create Vault 0 for 10 days', async() => {

        let vault0TotalDays = 10;

        await token.approve(vaults.address, totalVault0Rewards);

        await vaults.createVault(
            token.address,
            token.address,
            false,
            vault0TotalDays,
            0,
            totalVault0Rewards
        );
        describe('Valid deposits', () => {
            it('Validate non zero deposit', async() => {
                await token.connect(addr1).approve(vaults.address, vault0);
                await expect(vaults.connect(addr1).deposit(
                    vault0,
                    0,
                    0,
                )).to.be.revertedWith('Deposit must be greater than zero');
            });
        });

        describe('Validate rewards  Vault 0', () => {
            const userBag = 100 * gwei;

            it('Validate zero rewards after first deposit user', async() => {
                await token.connect(addr1).approve(vaults.address, userBag);
                await vaults.connect(addr1).deposit(
                    vault0,
                    0,
                    userBag,
                );

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr1.address);
                expect(parseInt(userReward)).to.be.equal(0);
            });

            it('Whithdraw after 7 day of user2 with weight 1.7 and user3 with weight 1.3', async() => {
                await ethers.provider.send('evm_increaseTime', [oneDay]);
                await ethers.provider.send("evm_mine");
                await token.connect(addr2).approve(vaults.address, userBag);
                await vaults.connect(addr2).deposit(
                    vault0,
                    7,
                    userBag,
                );
                await token.connect(addr3).approve(vaults.address, userBag);
                await vaults.connect(addr3).deposit(
                    vault0,
                    3,
                    userBag,
                );

                await ethers.provider.send('evm_increaseTime', [oneDay * 7]);
                await ethers.provider.send("evm_mine");

                await vaults.connect(addr2).withdraw(vault0);
                await vaults.connect(addr3).withdraw(vault0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr2.address);
                userReward2 = parseInt(userReward / gwei);
                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr3.address);
                userReward3 = parseInt(userReward / gwei);

                expect(userReward2).to.be.equal(297);
                expect(userReward3).to.be.equal(227);
            });

            it('User1 claim and reinvest reward on 7th day', async() => {
                await vaults.connect(addr1).claimRewards(vault0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr1.address);
                userReward1 = parseInt(userReward / gwei);
                userRewardWithdraw = parseInt(userRewardWithdraw / gwei);

                expect(userReward1).to.be.equal(userRewardWithdraw);

                await token.connect(addr1).approve(vaults.address, userRewardWithdraw);
                await vaults.connect(addr1).deposit(
                    vault0,
                    0,
                    userRewardWithdraw,
                );
            });

            it('Whithdraw after 1 day of user2 with weight 1.1 and user3 with weight 1', async() => {
                await token.connect(addr2).approve(vaults.address, userBag);
                await vaults.connect(addr2).deposit(
                    vault0,
                    1,
                    userBag,
                );
                await token.connect(addr3).approve(vaults.address, userBag);
                await vaults.connect(addr3).deposit(
                    vault0,
                    0,
                    userBag,
                );

                await ethers.provider.send('evm_increaseTime', [oneDay * 1]);
                await ethers.provider.send("evm_mine");

                await vaults.connect(addr2).withdraw(vault0);
                await vaults.connect(addr3).withdraw(vault0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr2.address);
                userReward2 = parseInt(userReward / gwei);
                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr3.address);
                userReward3 = parseInt(userReward / gwei);

                expect(userReward2).to.be.equal(297 + 35);
                expect(userReward3).to.be.equal(227 + 32);
            });

            it('Withdrawal of the user1 of all 10 days invested with weight 1', async() => {
                await ethers.provider.send('evm_increaseTime', [oneDay * 2]);
                await ethers.provider.send("evm_mine");
                await vaults.connect(addr1).withdraw(0);

                [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
                await vaults.getUserInfo(vault0, addr1.address);
                userReward1 = parseInt(userReward / gwei);

                expect(userReward1).to.be.equal(406);
            });

            it('Total rewards achieved', async() => {
                userReward = (userReward1 + userReward2 + userReward3) * gwei;
                expect(userReward).to.be.lessThanOrEqual(totalVault0Rewards);
                expect(userReward).to.be.greaterThanOrEqual(parseInt(totalVault0Rewards * 0.9));
            });
        });
    });

    // it('Create Vault 1 for 100 days', async() => {

    //     let vault1TotalDays = 100;

    //     await token.approve(vaults.address, totalVault1Rewards);

    //     await vaults.createVault(
    //         token.address,
    //         token.address,
    //         false,
    //         vault1TotalDays,
    //         20,
    //         totalVault1Rewards
    //     );

    //     describe('Validate rewards Vault 1', () => {
    //         const userBag = 10000 * gwei;

    //         it('User1 deposit 10k for 20 days and User2 deposti 10k for 40 days on the first day of the Vault 1', async() => {
    //             await token.connect(addr1).approve(vaults.address, userBag);
    //             await vaults.connect(addr1).deposit(
    //                 vault1,
    //                 20,
    //                 userBag,
    //             );
    //             await token.connect(addr2).approve(vaults.address, userBag);
    //             await vaults.connect(addr2).deposit(
    //                 vault1,
    //                 40,
    //                 userBag,
    //             );

    //             [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
    //             await vaults.getUserInfo(0, addr1.address);
    //             expect(parseInt(userReward)).to.be.equal(0);
    //         });

    //         it('User1 and User2 Withdraw after 100 days on the Vault 1', async() => {
    //             await ethers.provider.send('evm_increaseTime', [oneDay * 100]);
    //             await ethers.provider.send("evm_mine");

    //             await vaults.connect(addr1).withdraw(vault1);
    //             await vaults.connect(addr2).withdraw(vault1);
    //             [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
    //             await vaults.getUserInfo(vault1, addr1.address);
    //             userReward1 = parseInt(userReward / gwei);
    //             // console.log(parseInt(userWeight))

    //             [userAmount, userWeight, userReward, userRewardWithdraw, userLockTime] =
    //             await vaults.getUserInfo(vault1, addr2.address);
    //             userReward2 = parseInt(userReward / gwei);
    //             // console.log(parseInt(userWeight) / gwei)

    //             expect(userReward1).to.be.equal(46152);
    //             expect(userReward2).to.be.equal(53844);
    //         });

    //         it('Total rewards achieved on Vault 1', async() => {
    //             userReward = (userReward1 + userReward2) * gwei;
    //             expect(userReward).to.be.lessThanOrEqual(totalVault1Rewards);
    //             expect(userReward).to.be.greaterThanOrEqual(parseInt(totalVault1Rewards * 0.9));
    //         });
    //     });
    // });
});