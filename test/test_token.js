const {expect} = require('chai');
const {utils} = require('ethers');
const {isAddress} = require('ethers/lib/utils');

describe('ETH MINT BURN', () => {
    let Token, token, vault, Vault, owner, addr1, addr2;

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
            console.log((await token.totalSupply()).toString());
            console.log(parseInt(await token.balanceOf(addr1.address)));
            console.log(parseInt(await token.balanceOf(addr2.address)));
            console.log(parseInt(await token.balanceOf(owner.address)));
            console.log(parseInt(await token.balanceOf(vault.address)));
        });
    });

});