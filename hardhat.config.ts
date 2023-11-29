import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require('dotenv').config();

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.19',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  networks: {
    Klatyn_Baobab: {
      url: "https://api.baobab.klaytn.net:8651",
      accounts: [process.env.PRIVATE_KEY2 as string]
    }
  },
};

export default config;
