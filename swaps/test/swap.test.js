const { expect } = require("chai");
const { ethers } = require("hardhat");

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
const WETH9 = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";

describe("Swap examples", () => {
    let SwapContract;
    let accounts;

    let dai;
    let weth9;
    let usdc;

    beforeEach(async () => {
        let swap = await ethers.getContractFactory("V3TokenSwaps");
        SwapContract = await swap.deploy();
        await SwapContract.waitForDeployment();
        accounts = await ethers.getSigners();

        dai = await ethers.getContractAt(
            "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
            DAI,
        );
        weth9 = await ethers.getContractAt("IWETH9", WETH9);
        usdc = await ethers.getContractAt(
            "@openzeppelin/contracts/token/ERC20/IERC20.sol:IERC20",
            USDC,
        );
    });

    async function getBalance(address, token) {
        let balance = await token.balanceOf(address.address);
        return balance;
    }

    it("should swapExactInputSingle", async function () {
        const amountIn = 10n ** 18n; // 1 ETH
        await weth9.connect(accounts[0]).deposit({ value: amountIn });
        await weth9
            .connect(accounts[0])
            .approve(await SwapContract.target, amountIn);

        console.log(
            "WETH9 balance before: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance before: ", await getBalance(accounts[0], dai));
        await SwapContract.swapExactInputSingle(amountIn);

        console.log(
            "WETH9 balance after: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance after: ", await getBalance(accounts[0], dai));
    });

    it("should swapExactOutputSingle", async function () {
        const wethAmoutInMax = 10n ** 18n;
        const daiAmountOut = 100n * 10n ** 18n;

        await weth9.connect(accounts[0]).deposit({ value: wethAmoutInMax });
        await weth9
            .connect(accounts[0])
            .approve(await SwapContract.target, wethAmoutInMax);

        console.log(
            "\nWETH9 balance before: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance before: ", await getBalance(accounts[0], dai));
        await SwapContract.swapExactOutputSingle(daiAmountOut, wethAmoutInMax);

        console.log(
            "WETH9 balance after: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance after: ", await getBalance(accounts[0], dai));
    });

    it("should swapExactInputMultihop", async function () {
        const amountIn = 10n ** 18n; // 1 ETH
        await weth9.connect(accounts[0]).deposit({ value: amountIn });
        await weth9
            .connect(accounts[0])
            .approve(await SwapContract.target, amountIn);

        console.log(
            "WETH9 balance before: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance before: ", await getBalance(accounts[0], dai));
        await SwapContract.swapExactInputMultihop(amountIn);

        console.log(
            "WETH9 balance after: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance after: ", await getBalance(accounts[0], dai));
    });

    it("should swapExactOutputMultihop", async function () {
        const wethAmoutInMax = 10n ** 18n;
        const daiAmountOut = 100n * 10n ** 18n;

        await weth9.connect(accounts[0]).deposit({ value: wethAmoutInMax });
        await weth9
            .connect(accounts[0])
            .approve(await SwapContract.target, wethAmoutInMax);

        console.log(
            "\nWETH9 balance before: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance before: ", await getBalance(accounts[0], dai));
        await SwapContract.swapExactOutputMultihop(
            daiAmountOut,
            wethAmoutInMax,
        );

        console.log(
            "WETH9 balance after: ",
            await getBalance(accounts[0], weth9),
        );
        console.log("DAI balance after: ", await getBalance(accounts[0], dai));
    });
});
