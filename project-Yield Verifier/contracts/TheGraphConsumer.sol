// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract TheGraphConsumer is AccessControl {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // Struct to store subgraph query results
    struct SubgraphData {
        uint256[] timestamps;
        uint256[] yieldRates;
        uint256[] depositEvents;
        uint256[] withdrawalEvents;
    }

    // Mapping to store cached query results
    mapping(bytes32 => SubgraphData) private queryCache;
    mapping(bytes32 => uint256) private queryCacheTimestamp;

    uint256 public constant CACHE_DURATION = 1 hours;
    string public subgraphEndpoint;

    event SubgraphEndpointUpdated(string newEndpoint);
    event DataCached(bytes32 indexed queryHash, uint256 timestamp);

    constructor(string memory _subgraphEndpoint) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ORACLE_ROLE, msg.sender);
        subgraphEndpoint = _subgraphEndpoint;
    }

    function queryHistoricalData(uint256 startTime, uint256 endTime)
        external
        view
        returns (
            uint256[] memory timestamps,
            uint256[] memory yieldRates,
            uint256[] memory depositEvents,
            uint256[] memory withdrawalEvents
        )
    {
        bytes32 queryHash = keccak256(abi.encodePacked(startTime, endTime));
        SubgraphData storage cachedData = queryCache[queryHash];

        // Return cached data if it's still valid
        if (queryCacheTimestamp[queryHash] + CACHE_DURATION > block.timestamp) {
            return (
                cachedData.timestamps,
                cachedData.yieldRates,
                cachedData.depositEvents,
                cachedData.withdrawalEvents
            );
        }

        // If cache is invalid, revert - data must be updated by oracle
        revert("Cache expired - needs update from oracle");
    }

    function updateHistoricalData(
        uint256 startTime,
        uint256 endTime,
        uint256[] calldata timestamps,
        uint256[] calldata yieldRates,
        uint256[] calldata depositEvents,
        uint256[] calldata withdrawalEvents
    ) external onlyRole(ORACLE_ROLE) {
        require(timestamps.length > 0, "Empty data");
        require(
            timestamps.length == yieldRates.length &&
            timestamps.length == depositEvents.length &&
            timestamps.length == withdrawalEvents.length,
            "Array length mismatch"
        );

        bytes32 queryHash = keccak256(abi.encodePacked(startTime, endTime));

        // Update cache
        queryCache[queryHash] = SubgraphData({
            timestamps: timestamps,
            yieldRates: yieldRates,
            depositEvents: depositEvents,
            withdrawalEvents: withdrawalEvents
        });
        queryCacheTimestamp[queryHash] = block.timestamp;

        emit DataCached(queryHash, block.timestamp);
    }

    function setSubgraphEndpoint(string memory _subgraphEndpoint) external onlyRole(DEFAULT_ADMIN_ROLE) {
        subgraphEndpoint = _subgraphEndpoint;
        emit SubgraphEndpointUpdated(_subgraphEndpoint);
    }
}