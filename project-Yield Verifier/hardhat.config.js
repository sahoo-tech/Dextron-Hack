require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

const { generatePrivateKey } = require("@ethersproject/random");

// Generate a new private key if not provided in .env
const privateKey = process.env.PRIVATE_KEY || generatePrivateKey();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          viaIR: true,
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.4.24",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks: {
    hardhat: {
      chainId: 1337
    },
    testnet: {
      url: process.env.TESTNET_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
      chainId: 97,
      gasPrice: 20000000000,
      timeout: 60000,
      confirmations: 2
    }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  }
}