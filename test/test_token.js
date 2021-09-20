const {expect} = require('chai');
const {utils} = require('ethers');
const {isAddress} = require('ethers/lib/utils');

describe('ETH MINT BURN', () => {
    let Token, token,  vault, Vault, owner, addr1, addr2;

  beforeEach(async () => {
        Token = await ethers.getContractFactory('NoFeeToken');
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
        token = await Token.deploy(
            'test', 'TESTX', 1000000 * 10 ** 18
        );

        console.log(token);

    });


    describe('unlock tokens', () => {

    });

});