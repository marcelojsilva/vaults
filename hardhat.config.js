/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('@nomiclabs/hardhat-waffle');
require('dotenv').config({path: __dirname + '/.env'});
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");

task('accounts', "Print all accounts").setAction(async () => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
})

module.exports = {
    networks: {
        hardhat: {
            // allowUnlimitedContractSize: true
            blockGasLimit: 60000000,
            gasPrice: 4000000000
        }
    },
    gasReporter: {
        currency: 'USD',
        gasPrice: 40
    },
    solidity: {
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            }
        },
        compilers: [
            {
                version: "0.6.12",
            },
            {
                version: "0.5.0",
            },
            {
                version: "0.6.2",
            },
            {
                version: "0.8.0",
            },
        ],
    }
};