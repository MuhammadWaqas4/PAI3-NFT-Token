require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
    solidity: {
        compilers: [
            {
                version: "0.8.26",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1000000
                    }
                }
            }
        ]
    },
    defaultNetwork: "mainnet",
    networks: {
        staging: {
            url: process.env.URL_STAGING ? process.env.URL_STAGING : "https://rpc.example.org/",
            accounts: [
                process.env.PRIVATE_KEY_STAGING
                    ? process.env.PRIVATE_KEY_STAGING
                    : "0x0000000000000000000000000000000000000000000000000000000000000000"
            ]
        },
        mainnet: {
            url: process.env.URL_MAINNET ? process.env.URL_MAINNET : "https://mainnet.infura.io/v3/",
            accounts: [
                process.env.PRIVATE_KEY_MAINNET
                    ? process.env.PRIVATE_KEY_MAINNET
                    : "0x0000000000000000000000000000000000000000000000000000000000000000"
            ]
        }
    },
    etherscan: {
        apiKey: {
            staging: process.env.BLOCK_EXPLORER_API_KEY_STAGING,
            mainnet: process.env.BLOCK_EXPLORER_API_KEY_MAINNET
        }
    }
};
