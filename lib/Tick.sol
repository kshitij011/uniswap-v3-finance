// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.31;

import "./TickMath.sol";

library Tick {
    function tickSpacingToMaxLiquidityPerTick(int24 tickSpacing) internal pure returns(uint128){
        // gives minTick that is multiple of tickSpacing
        int24 minTick = (TickMath.MIN_TICK / tickSpacing) * tickSpacing;
        int24 maxTick = (TickMath.MAX_TICK / tickSpacing) * tickSpacing;
        uint24 numTicks = uint24(int24(maxTick - minTick) / tickSpacing) + 1;
        return type(uint128).max / numTicks;
    }
}