import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
// import "@typechain/hardhat";
import dotenv from "dotenv";
import "hardhat-abi-exporter";
import "hardhat-contract-sizer";
import "@openzeppelin/hardhat-upgrades";
import "hardhat-gas-reporter";
// import "@primitivefi/hardhat-dodoc";
import { HardhatUserConfig } from "hardhat/config";
import { NetworkUserConfig } from "hardhat/types";

dotenv.config();



// Ensure that we have all the environment variables we need.
const privateKey = process.env.D_PRIVATE_KEY || '7d7304de75e779a80485ba8b18b3ae5ae9c889063d8d28522a7f27693bb6700d';

const config = {
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.12",
    settings: {
      metadata: {
        bytecodeHash: "ipfs",
      },
      // You should disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 490,
      },
    },
  },
  networks: {
    hardhat: {
      chainId: 1337,
    },
    goerli: {
  		// url: `ADD_YOUR_QUICKNODE_URL_HERE`,
  		url: `https://eth-goerli.g.alchemy.com/v2/NazHWAZHwwVkim06LfZvjohuzpgnmC_m`,
  		accounts: [privateKey]
  	}
  },
};

config.networks = {
  ...config.networks,
  hardhat: {
    chainId: 1337,
  },
};

export default config;
