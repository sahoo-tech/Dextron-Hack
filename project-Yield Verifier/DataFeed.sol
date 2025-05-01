// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@uniswap/v3-core/contracts/libraries/FullMath.sol";

contract DataFeed is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    struct YieldData {
        uint256 timestamp;
        uint256 yieldRate;
        uint256[] depositWithdrawalEvents;
    }

    struct Observation {
        uint32 blockTimestamp;
        int56 tickCumulative;
        uint160 secondsPerLiquidityCumulativeX128;
        bool initialized;
    }

    mapping(uint256 => YieldData) private historicalData;
    uint256[] private timestamps;

    IUniswapV3Pool public immutable pool;
    uint32 public constant TWAP_PERIOD = 1800; // 30 minutes

    event DataUpdated(uint256 indexed timestamp, uint256 yieldRate);
    event EventsRecorded(uint256 indexed timestamp, uint256[] events);

    constructor(address _pool) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
        pool = IUniswapV3Pool(_pool);
    }

    function updateYieldData(uint256 timestamp) external onlyRole(ORACLE_ROLE) {
        require(timestamp <= block.timestamp, "Invalid timestamp");

        uint256 yieldRate = getTWAP();

        if (historicalData[timestamp].timestamp == 0) {
            timestamps.push(timestamp);
        }

        historicalData[timestamp].timestamp = timestamp;
        historicalData[timestamp].yieldRate = yieldRate;

        emit DataUpdated(timestamp, yieldRate);
    }

    function recordEvents(uint256 timestamp, uint256[] calldata events) external onlyRole(ORACLE_ROLE) {
        require(timestamp <= block.timestamp, "Invalid timestamp");
        require(events.length > 0, "No events provided");

        historicalData[timestamp].depositWithdrawalEvents = events;
        emit EventsRecorded(timestamp, events);
    }

    function getHistoricalYield(uint256 timestamp) external view returns (uint256) {
        require(historicalData[timestamp].timestamp > 0, "No data for timestamp");
        return historicalData[timestamp].yieldRate;
    }

    function getDepositWithdrawalEvents(uint256 startTime, uint256 endTime)
        external
        view
        returns (uint256[] memory)
    {
        uint256[] memory allEvents;
        uint256 eventCount = 0;

        for (uint256 i = 0; i < timestamps.length; i++) {
            if (timestamps[i] >= startTime && timestamps[i] <= endTime) {
                uint256[] storage events = historicalData[timestamps[i]].depositWithdrawalEvents;
                eventCount += events.length;
            }
        }

        allEvents = new uint256[](eventCount);
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < timestamps.length; i++) {
            if (timestamps[i] >= startTime && timestamps[i] <= endTime) {
                uint256[] storage events = historicalData[timestamps[i]].depositWithdrawalEvents;
                for (uint256 j = 0; j < events.length; j++) {
                    allEvents[currentIndex] = events[j];
                    currentIndex++;
                }
            }
        }

        return allEvents;
    }

    function getTWAP() public view returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = TWAP_PERIOD; // from (before)
        secondsAgos[1] = 0; // to (now)

        (int56[] memory tickCumulatives, ) = pool.observe(secondsAgos);

        int56 tickCumulativesDelta = tickCumulatives[1] - tickCumulatives[0];
        int24 timeWeightedAverageTick = int24(tickCumulativesDelta / int56(uint56(TWAP_PERIOD)));

        // Convert tick to price
        uint160 sqrtPriceX96 = TickMath.getSqrtRatioAtTick(timeWeightedAverageTick);
        uint256 priceX96 = FullMath.mulDiv(sqrtPriceX96, sqrtPriceX96, 1 << 96);
        
        return priceX96;
    }

    function getLatestYieldRate() external view returns (uint256) {
        return getTWAP();
    }
}