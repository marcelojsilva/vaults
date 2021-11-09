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
        vaults = await VaultContract.deploy(token.address);

        token.transfer(addr1.address, bag);
        token.transfer(addr2.address, bag);
        token.transfer(addr3.address, bag);
    });


    it('testar nova distribuicao', async() => {


    });
});