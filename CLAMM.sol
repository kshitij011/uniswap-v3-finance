// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.31;

// CLAMM: Contrated Liquidity Automated Market Maker

import "./interfaces/IERC20.sol";
import "./lib/Tick.sol";
import "./lib/Position.sol";
import "./lib/SafeCast.sol";
import "./lib/SqrtPriceMath.sol";

contract CLAMM {
    using SafeCast for int256;
    using Tick for mapping(int24 => Tick.Info);
    using Position for mapping(bytes32 => Position.Info);
    using Position for Position.Info;


    address immutable token0;
    address immutable token1;
    uint24 immutable fee;
    int24 immutable tickSpacing;
    uint128 immutable maxLiquidityPerTick;

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
    uint128 public liquidity;

    // position has to be state variable as it is returned from storage.
    mapping(bytes32 => Position.Info) public positions;
    mapping(int24 => Tick.Info) public ticks;

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

        maxLiquidityPerTick = Tick.tickSpacingToMaxLiquidityPerTick(_tickSpacing);
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
        int128 liquidityDelta;
    }

    function checkTicks(int24 tickLower, int24 tickUpper) private pure{
        require(tickLower < tickUpper, 'TLU');
        require(tickLower >= TickMath.MIN_TICK, 'TLM');
        require(tickUpper <= TickMath.MAX_TICK, 'TUM');
    }

    function _updatePosition(
        address owner,
        int24 tickLower,
        int24 tickUpper,
        int128 liquidityDelta,
        int24 tick
    ) private returns (Position.Info storage position) {
        position = positions.get(owner, tickLower, tickUpper);

        // uint256 _feeGrowthGlobal0x128 = feeGrowthGlobal0X128;
        uint256 _feeGrowthGlobal0x128 = 0;  // for now
        uint256 _feeGrowthGlobal1x128 = 0;  // for now

        bool flippedLower;
        bool flippedUpper;

        if(liquidityDelta != 0) {
            flippedLower = ticks.update(
                tickLower,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0x128,
                _feeGrowthGlobal1x128,
                false,
                maxLiquidityPerTick
            );

            flippedUpper = ticks.update(
                tickUpper,
                tick,
                liquidityDelta,
                _feeGrowthGlobal0x128,
                _feeGrowthGlobal1x128,
                true,
                maxLiquidityPerTick
            );
        }

        position.update(liquidityDelta, 0, 0);

        if(liquidityDelta < 0) {
            if(flippedLower) {
                ticks.clear(tickLower);
            }
            if(flippedUpper) {
                ticks.clear(tickUpper);
            }
        }

    }

    function _modifyPosition(ModifyPositionParams memory params) private returns (Position.Info storage position, int256 amount0, int256 amount1) {
        checkTicks(params.tickLower, params.tickUpper);

        // load into memory to save gas (reading from storage slots consume more gas)
        Slot0 memory _slot0 = slot0;

        position = _updatePosition(
            params.owner,
            params.tickLower,
            params.tickUpper,
            params.liquidityDelta,
            _slot0.tick
        );

        if(params.liquidityDelta != 0) {

            // calculate liquidity when current price is less than lower price range
            if(_slot0.tick < params.tickLower) {
                amount0 = SqrtPriceMath.getAmount0Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );

                // when the current price is between two price ranges
            } else if (_slot0.tick < params.tickUpper) {
                amount0 = SqrtPriceMath.getAmount0Delta(
                    _slot0.sqrtPriceX96,
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );

                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    _slot0.sqrtPriceX96,
                    params.liquidityDelta
                );

                // Update current liquidity
                liquidity = params.liquidityDelta < 0
                ? liquidity - uint128(-params.liquidityDelta)
                : liquidity + uint128(params.liquidityDelta);

                // calculate liquidity when current price is less than lower price range
            } else {
                amount1 = SqrtPriceMath.getAmount1Delta(
                    TickMath.getSqrtRatioAtTick(params.tickLower),
                    TickMath.getSqrtRatioAtTick(params.tickUpper),
                    params.liquidityDelta
                );
            }
        }

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