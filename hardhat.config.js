require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config(); // Optional (for environment variables)

module.exports = {
    solidity: "0.8.0",
    networks: {
        // Local network (for testing)
        hardhat: {},

        // Goerli Testnet (example)
        goerli: {
            url: process.env.ALCHEMY_GOERLI_URL, //environment variables
            accounts: [process.env.PRIVATE_KEY], // Wallet private key
        },

        // Add other networks (e.g., Mainnet) as needed
    }
};