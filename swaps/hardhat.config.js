require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
    solidity: "0.7.6",
    networks: {
        hardhat: {
            forking: {
                url: process.env.ALCHEMY_URL,
                blockNumber: 19000000,
            },
            gasPrice: "auto",
            initialBaseFeePerGas: 0,
        },
    },
};
