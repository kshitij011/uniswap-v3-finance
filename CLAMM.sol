// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.31;

// CLAMM: Contrated Liquidity Automated Market Maker

import "./interfaces/IERC20.sol";
import "./lib/Tick.sol";
import "./lib/Position.sol";
import "./lib/SafeCast.sol";

contract CLAMM {
    using SafeCast for int256;

    address immutable token0;
    address immutable token1;
    uint24 immutable fee;
    int24 immutable tickSpacing;
    int128 immutable maxLiquidityPerTick;

    // 32-bytes solt
    // Note: Price oracles and fee protocol is ignored in this tutorial.
    struct Slot0 {  // total size is 31 bytes < 32 bytes.
        // the current price
        // 160 bits / 8 = 20 bytes
        uint160 sqrtPriceX96;

        // the current tick. 3 bytes
        int24 tick;

        // the most recently updated index of the observations array
        // uint16 observationIndex;

        // the current maximum number of observations that are being stored. 2 bytes
        // uint16 observationCardinality;

        // the next maximum number of observations to store, triggered in observations.write
        // uint16 observationCardinalityNext;

        // the current protocol fee as % of the swap fee taken on withdrawal. 1 byte
        // uint8 feeProtocol;

        // weather the pool is locked. 1 byte.
        bool unlocked;
    }

    Slot0 public slot0;

    // position has to be state variable as it is returned from storage.
    mapping(bytes32 => Position.Info) public positions;

    modifier lock() {
        require(slot0.unlocked, "locked");
        slot0.unlocked = false;
        _;
        slot0.unlocked = true;
    }

    constructor(
        address _token0,
        address _token1,
        uint24 _fee,
        int24 _tickSpacing
    ) {
        require(_token0 != address(0), "invalid token0 address");
        require(_token1 != address(0), "invalid token1 address");
        require(_tickSpacing > 0, "tick spacing 0");
        require(_tickSpacing > 0, "fee spacing 0");

        token0 = _token0;
        token1 = _token1;
        tickSpacing = _tickSpacing;
        fee = _fee;

        maxLiquidityPerTick = int128(Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing));
    }

    function initialize(uint160 sqrtPriceX96) external {
        require(slot0.sqrtPriceX96 == 0, "already initialized!");
        int24 tick = TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        slot0 = Slot0({
            sqrtPriceX96: sqrtPriceX96,
            tick: tick,
            unlocked:true
        });
    }

    struct ModifyPositionParams {
        address owner;
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
    }

    function _modifyPosition(ModifyPositionParams memory params) private view returns (Position.Info storage position, int256 amount0, int256 amount1) {
        return (positions[bytes32(0)],0,0);
    }

    // mint liquidity tokens to the recipient based on the amount aupplied.
    function mint(
        address recipient,
        int24 tickLower,
        int24 tickUpper,
        uint128 amount
    ) external lock returns(uint amount0, uint amount1) {
        require(amount > 0, "amount is 0!");
        (, int256 amount0Int, int256 amount1Int) =
        _modifyPosition(
            ModifyPositionParams({
                owner: recipient,
                tickLower: tickLower,
                tickUpper: tickUpper,
                liquidityDelta: int256(uint256(amount)).toInt128()
            })
        );

        amount0 = uint256(amount0Int);
        amount1 = uint256(amount1Int);

        if(amount0 > 0) {
            IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        }
        if(amount1 > 0) {
            IERC20(token1).transferFrom(msg.sender, address(this), amount0);
        }
    }
}