# Concentrated Liquidity Automated Market Maker Notes

This is the tutorial of how the Uniswap V3 works under the hood.

**tickSpacing**:
Tick spacing in the Uniswap v3 refers to the price indices, this is a parameter that controls which price ticks liquidity providers are allowed to use.
LP's choose a price range to provide concentrated liquidity between the price indices that are multipe of the tick spacing.

Ex: if tick spacing is 10, then the valid ticks are:
..., -20, -10, 0, 10, 20, 30, ...
LP's can set their concentrated liquidity between these ranges (10 to 30) and earn fees when the liquidity ranges between them.
LP's cannot set the concentration between 15 to 25, because that is not multiplw of tick spacing.
tick spacing has nothing to do with pricing of the tokens, they are just price indices used for reference while providing liquidity.

Why tick spacing?
If every single tick would be usable, there would be millions of possible tick values.
The contract would need to store too many initialized ticks, increasing storage slots used and gas used.
By spacing ticks out there will be
fewer possible positions
less storage required
cheaper swaps

**tick**:
A tick is an integer index that represents a specific price level.
Uniswap V3 defines the relationship between price and tick as

```bash
price = 1.0001 ^ tick
```

where price = token0/token1
tick = integer (can be -'ve' or +'ve')
Each tick represents 0.01% relative price change.

So,
+1 tick = +0.01%
+100 tick = +1%
+6931 tick = 2x price

2. Why Does Tick Exist?

Ticks exist for liquidity accounting, not for pricing.

In Uniswap V3:

- Liquidity providers (LPs) provide liquidity within a price range.
- Liquidity must activate when price enters a range.
- Liquidity must deactivate when price leaves a range.
  Ticks act as boundary markers where liquidity turns on or off.

Without ticks:

- The contract would need continuous price boundary checks.
- Storage and gas costs would explode.
- Liquidity activation would be inefficient.

So:
Ticks allow efficient, discrete liquidity boundary management.

**maxLiquidityPerTick**: This function returns the maximum liquidity between two ticks.

## Functions

**initialize()**:
called afer the contract is deployed to initialize the values (set the initial price).
takes in argument sqrtPriceX96

**slot0**:
It stores important variables of the smart contract, whose total memory does not exceed 32 bytes and are stored in first storage slotof the contract.

**sqrtPriceX96**:
It is the square root of price multiplied by some scaler.

```bash
sqrtPriceX96 = sqrt(P) * (2 ** 96)
```

**mint()**:
When we add liquidity to the contract, mint() function is called
