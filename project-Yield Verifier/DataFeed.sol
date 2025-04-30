// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DataFeed is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    struct YieldData {
        uint256 timestamp;
        uint256 yieldRate;
        uint256[] depositWithdrawalEvents;
    }

    mapping(uint256 => YieldData) private historicalData;
    uint256[] private timestamps;

    AggregatorV3Interface private yieldOracle;

    event DataUpdated(uint256 indexed timestamp, uint256 yieldRate);
    event EventsRecorded(uint256 indexed timestamp, uint256[] events);

    constructor(address _yieldOracle) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
        yieldOracle = AggregatorV3Interface(_yieldOracle);
    }

    function updateYieldData(uint256 timestamp, uint256 yieldRate) external onlyRole(ORACLE_ROLE) {
        require(timestamp <= block.timestamp, "Invalid timestamp");

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

    function getLatestYieldRate() external view returns (uint256) {
        (, int256 price, , , ) = yieldOracle.latestRoundData();
        require(price >= 0, "Invalid yield rate");
        return uint256(price);
    }

    function setYieldOracle(address _yieldOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        yieldOracle = AggregatorV3Interface(_yieldOracle);
    }
}