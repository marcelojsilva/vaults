const {expect} = require('chai');
const {utils} = require('ethers');
const {isAddress} = require('ethers/lib/utils');

describe('ETH MINT BURN', () => {
    let Token, token, vault, Vault, owner, addr1, addr2;
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


    describe('Use vault', () => {

        it('Happy path', async () => {

            let ownerBag = ethers.utils.parseUnits("200000", "gwei");

            await token.approve(vault.address, ownerBag);
  
            await vault.createVault(
              token.address,
              false,
              ownerBag
            );

            let result = await vault.getVault(0);
            
            const {
                0: vid,
                1: tokenAddr,
                2: vaultTokenReserve,
                3: startBlockTime,
                4: endBlockTime,
            } = result;

            console.log(result);

            const userBag = ethers.utils.parseUnits("50000", "gwei")

            //await network.provider.send("evm_increaseTime", [3600])

            await token.connect(addr1).approve(vault.address, userBag);

            vault.connect(addr1).deposit(
                0,
                1632958826,
                userBag,
            );

            console.log((await vault.getUserVaultAmount(0, addr1.address)).toString())

            
            console.log((await token.totalSupply()).toString());
            console.log(parseInt(await token.balanceOf(addr1.address)));
            console.log(parseInt(await token.balanceOf(addr2.address)));
            console.log(parseInt(await token.balanceOf(owner.address)));
            console.log(parseInt(await token.balanceOf(vault.address)));

         });
    });

});