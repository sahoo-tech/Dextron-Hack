// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ITheGraphConsumer {
    function queryHistoricalData(uint256 startTime, uint256 endTime) external view returns (
        uint256[] memory timestamps,
        uint256[] memory yieldRates,
        uint256[] memory depositEvents,
        uint256[] memory withdrawalEvents
    );
}

contract TheGraphDataFeed is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant GRAPH_CONSUMER_ROLE = keccak256("GRAPH_CONSUMER_ROLE");

    struct YieldData {
        uint256 timestamp;
        uint256 yieldRate;
        uint256[] depositWithdrawalEvents;
        uint256 totalDeposits;
        uint256 totalWithdrawals;
        uint256 utilizationRatio;
    }

    mapping(uint256 => YieldData) private historicalData;
    uint256[] private timestamps;
    ITheGraphConsumer private graphConsumer;
    AggregatorV3Interface private yieldOracle;

    event DataUpdated(uint256 indexed timestamp, uint256 yieldRate, uint256 utilizationRatio);
    event EventsRecorded(uint256 indexed timestamp, uint256[] events);

    constructor(address _yieldOracle, address _graphConsumer) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
        _setupRole(GRAPH_CONSUMER_ROLE, _graphConsumer);
        yieldOracle = AggregatorV3Interface(_yieldOracle);
        graphConsumer = ITheGraphConsumer(_graphConsumer);
    }

    function updateYieldData(
        uint256 timestamp,
        uint256 yieldRate,
        uint256 utilizationRatio
    ) external onlyRole(ORACLE_ROLE) {
        require(timestamp <= block.timestamp, "Invalid timestamp");

        if (historicalData[timestamp].timestamp == 0) {
            timestamps.push(timestamp);
        }

        historicalData[timestamp].timestamp = timestamp;
        historicalData[timestamp].yieldRate = yieldRate;
        historicalData[timestamp].utilizationRatio = utilizationRatio;

        emit DataUpdated(timestamp, yieldRate, utilizationRatio);
    }

    function recordEvents(
        uint256 timestamp,
        uint256[] calldata events,
        uint256 totalDeposits,
        uint256 totalWithdrawals
    ) external onlyRole(ORACLE_ROLE) {
        require(timestamp <= block.timestamp, "Invalid timestamp");
        require(events.length > 0, "No events provided");

        historicalData[timestamp].depositWithdrawalEvents = events;
        historicalData[timestamp].totalDeposits = totalDeposits;
        historicalData[timestamp].totalWithdrawals = totalWithdrawals;

        emit EventsRecorded(timestamp, events);
    }

    function getHistoricalData(uint256 startTime, uint256 endTime)
        external
        view
        returns (
            uint256[] memory _timestamps,
            uint256[] memory yieldRates,
            uint256[] memory depositEvents,
            uint256[] memory withdrawalEvents,
            uint256[] memory utilizationRatios
        )
    {
        // Query The Graph for historical data
        (_timestamps, yieldRates, depositEvents, withdrawalEvents) = graphConsumer.queryHistoricalData(
            startTime,
            endTime
        );

        // Get utilization ratios for the period
        utilizationRatios = new uint256[](_timestamps.length);
        for (uint256 i = 0; i < _timestamps.length; i++) {
            utilizationRatios[i] = historicalData[_timestamps[i]].utilizationRatio;
        }

        return (_timestamps, yieldRates, depositEvents, withdrawalEvents, utilizationRatios);
    }

    function getLatestYieldRate() external view returns (uint256) {
        (, int256 price, , , ) = yieldOracle.latestRoundData();
        require(price >= 0, "Invalid yield rate");
        return uint256(price);
    }

    function setGraphConsumer(address _graphConsumer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        graphConsumer = ITheGraphConsumer(_graphConsumer);
    }

    function setYieldOracle(address _yieldOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        yieldOracle = AggregatorV3Interface(_yieldOracle);
    }
}