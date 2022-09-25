require("@nomicfoundation/hardhat-toolbox");

require('dotenv').config();

const { REACT_APP_MNEMONIC, REACT_APP_ESCAPIKEY,  REACT_APP_INFURA_ID} = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks:{
    // mainnet: {
    //   url:`https://mainnet.infura.io/v3/${REACT_APP_INFURA_ID}`,
    //   accounts:[REACT_APP_MNEMONIC]
    // },
    rinkeby: {
      url:`https://rinkeby.infura.io/v3/${REACT_APP_INFURA_ID}`,
      accounts:[REACT_APP_MNEMONIC]
    },
    // testnet: {
    //   url: "https://data-seed-prebsc-1-s1.binance.org:8545",
    //   chainId: 97,
    //   accounts: [REACT_APP_MNEMONIC]
    // }
  },
  etherscan:{
    apiKey: REACT_APP_ESCAPIKEY
  }
};
