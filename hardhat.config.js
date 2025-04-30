require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
    networks: {
        sepolia: {
            url: process.env.ALCHEMY_SEPOLIA_URL,
            accounts: [process.env.PRIVATE_KEY],
        },
    },
};