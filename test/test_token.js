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
        vault = await Vault.deploy();

        const bag = ethers.utils.parseUnits("250000", "gwei")

        token.transfer(addr1.address, bag);
        token.transfer(addr2.address, bag);
    });


    it('Create Vault', async () => {

        let ownerBag = ethers.utils.parseUnits("1000", "gwei");

        await token.approve(vault.address, ownerBag);

        await vault.createVault(
            token.address,
            false,
            100,
            ownerBag
        );

    describe('Validate rewards - Formula: ((block.number - user.lastReawardBlock) * pointsPerBlock * user.amount / vault.userAmount)', () => {

            //Validate zero balance at beginning
            // [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] = 
            //     await vault.getUserVaultInfo(0, addr1.address);
            // expect(await userAmount.to.equal(0));
            
            const userBag = ethers.utils.parseUnits("100", "gwei");
            
            //await network.provider.send("evm_increaseTime", [3600])
            
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
            
            it('Validate rewards after 10 blocks and new deposit of the user1', async () => {
                const blockNum = await ethers.provider.getBlockNumber();
                
                for(var i=0; i<blockNum+10; i++) {
                    await ethers.provider.send('evm_mine');
                }
                
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    1632958826,
                    userBag,
                );
    
                [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] = 
                    await vault.getUserVaultInfo(0, addr1.address);
                expect(parseInt(await userReward)).to.be.equal(10 * 9800000000);
            });
            
            it('Validate rewards after 2 blocks and new deposit of the user1', async () => {
                await ethers.provider.send('evm_mine');
                await token.connect(addr1).approve(vault.address, userBag);
                await vault.connect(addr1).deposit(
                    0,
                    1632958826,
                    userBag,
                    );
                    
                    [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] = 
                    await vault.getUserVaultInfo(0, addr1.address);
                    expect(parseInt(await userReward)).to.be.equal(10 * 9800000000 + 2 * 9800000000);
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
                
                // it('Validate rewards after 10 blocks and new deposit of the user2', async () => {
                //     const blockNum = await ethers.provider.getBlockNumber();
                    
                //     for(var i=0; i<blockNum+10; i++) {
                //         await ethers.provider.send('evm_mine');
                //     }
                    
                //     await token.connect(addr1).approve(vault.address, userBag);
                //     await vault.connect(addr1).deposit(
                //         0,
                //         1632958826,
                //         userBag,
                //     );
        
                //     [userAmount, userLastReawardBlock, userReward, userRewardWithdraw, userLockTime] = 
                //         await vault.getUserVaultInfo(0, addr1.address);
                //     expect(parseInt(await userReward)).to.be.equal(10 * 9800000000); // TODO buscar saldo total do Vault para calcular
                // });
                
                // console.log('getUserVaultInfo:\n%s',
                //     (await vault.getUserVaultInfo(0, addr1.address)).toString()
                // );
                
                /*
                console.log((await token.totalSupply()).toString());
            console.log(parseInt(await token.balanceOf(addr1.address)));
            console.log(parseInt(await token.balanceOf(addr2.address)));
            console.log(parseInt(await token.balanceOf(owner.address)));
            */
            // console.log('before withdraw:%s', parseInt(await token.balanceOf(vault.address)));

            // await vault.connect(addr1).withdraw(0);

            // console.log('after withdraw:%s', parseInt(await token.balanceOf(vault.address)));

         });
    });

});