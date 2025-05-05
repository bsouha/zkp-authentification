require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.19",
  networks: {
    // goerli: {
    //   url: process.env.GOERLI_RPC_URL,  // <- this is undefined!
    //   accounts: [process.env.PRIVATE_KEY]  // <- this is undefined!
    // }
  }
};
