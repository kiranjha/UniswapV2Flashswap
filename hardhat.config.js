require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.5.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },
      {
        version: "0.5.16",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },
      {
        version: "0.6.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },

      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: `${ process.env.MAIINETFORK_RPC_URL_ALCHEMY }`, //https://mainnet.infura.io/v3/b8c3e81e118f4779a74cbc79998e5249 //"https://eth-mainnet.g.alchemy.com/v2/L_oS11HfVoD9bbhGF0CsFLebHpIiUFqo",
        blockNumber: 14390000
      }
    }
  }
};
