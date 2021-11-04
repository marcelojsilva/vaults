/**
 * @type import('hardhat/config').HardhatUserConfig
 */
require('@nomiclabs/hardhat-waffle');
require('dotenv').config({ path: __dirname + '/.env' });
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("solidity-coverage");

task('accounts', "Print all accounts").setAction(async() => {
    const accounts = await ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
})
module.exports = {
    solidity: {
        settings: {
            optimizer: {
                enabled: true,
                runs: 1,
            }
        },
        compilers: [
            {
                version: "0.4.18",
            },
            {
                version: "0.5.16",
            },
            {
                version: "0.6.12",
            },
            {
                version: "0.6.6",
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
            {
                version: "0.8.7",
            },
            {
                version: "0.8.3",
            },
            {
                version: "0.8.9",
            }
        ],
    },
    networks: {
        eth_testnet: {
            url: process.env.ENDPOINT_ETH,
            accounts: ['0x' + process.env.PRIVATE_KEY],
        },
        eth_ropsten_testnet: {
            url: process.env.ENDPOINT_TESTNET_ROPSTEN_ETH,
            accounts: ['0x' + process.env.PRIVATE_KEY],
            gas: 2000000,   // <--- Twice as much
            gasPrice: 10000000000,
        },
        hardhat: {
            allowUnlimitedContractSize: true,
            forking: {
                url: process.env.ENDPOINT_MAINNET_ETH,
                gas: "90022680",
            },
        },
        bsc_testnet: {
            url: process.env.ENDPOINT_TESTNET_BSC,
            accounts: ['0x' + process.env.PRIVATE_KEY]
        },
        bsc_mainnet: {
            url: process.env.ENDPOINT_MAINNET_BSC,
            accounts: ['0x' + process.env.PRIVATE_KEY]
        },
        node: {
            url: 'http://127.0.0.1:8545/',
            gas: 2000000,   // <--- Twice as much
            gasPrice: 10000000000,
            accounts: [
                '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
                '0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d',
                '0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a',
                '0x7c852118294e51e653712a81e05800f419141751be58f605c371e15141b007a6'
            ]
        },
    },
    etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://bscscan.com/
        apiKey: "RQ648R6TBWIMV62IQH8V1XV98BTTFGRRXP"
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    }
};
