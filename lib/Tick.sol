// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.31;

import "./TickMath.sol";

library Tick {
    struct Info {
        // total liquidity inside this tick
        uint128 liquidityGross;
        // amount of liquidity to be added / removed when this becomes active
        int128 liquidityNet;
        // fee growth per unit of liquidity on the _other_ side of this tick (relative to the current tick)
        // only has relative meaning, not absolute — the value depends on when the tick is initialized
        uint256 feeGrowthOutside0X128;
        uint256 feeGrowthOutside1X128;

        // data related to price oracles, omitted for now.
        // int56 tickCumulativeOutside;
        // uint160 secondsPerLiquidityOutsideX128;
        // uint32 secondsOutside;

        // weather this tick is initialized or not
        bool initialized;
    }

    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns(uint128){
        // gives minTick that is multiple of tickSpacing
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24(int24(maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }

    function update(
        mapping(int24 => Tick.Info) storage self,
        int24 tick,
        int24 tickCurrent,
        int128 liquidityDelta,
        uint256 feeGrowthGlobal0X128,
        uint256 feeGrowthGlobal1X128,
        bool upper,
        uint128 maxLiquidity
    ) internal view returns (bool flipped) {
        Info memory info = self[tick];
        uint128 liquidityGrossBefore = info.liquidityGross;
        uint128 liquidityGrossAfter = liquidityDelta < 0
        ? liquidityGrossBefore - uint128(-liquidityDelta)
        : liquidityGrossBefore - uint128(liquidityDelta);

        require(liquidityGrossAfter <= maxLiquidity, "liquidity > max");

        flipped = (liquidityGrossAfter == 0) != (liquidityGrossBefore == 0);
        if(liquidityGrossBefore == 0) {
            info.initialized = true;
        }
        info.liquidityGross = liquidityGrossAfter;

        info.liquidityNet = upper
        ? info.liquidityNet - liquidityDelta
        : info.liquidityNet + liquidityDelta;
    }

    function clear(mapping(int24 => Info) storage self, int24 tick) internal {
        delete self[tick];
    }
}