// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IDataFeed {
    function getHistoricalYield(uint256 timestamp) external view returns (uint256);
    function getDepositWithdrawalEvents(uint256 startTime, uint256 endTime) external view returns (uint256[] memory);
}

contract YieldVerifier is AccessControl, Pausable {
    using SafeMath for uint256;

    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");
    uint256 public constant MINIMUM_HISTORY_PERIOD = 180 days;
    uint256 public constant UPDATE_INTERVAL = 1 days;

    struct StrategyMetrics {
        uint256 performanceScore;
        uint256 benchmarkYield;
        uint256 lastUpdateTime;
        uint256 totalYield;
        uint256 volatility;
    }

    mapping(address => StrategyMetrics) public strategyMetrics;
    IDataFeed public dataFeed;

    event MetricsUpdated(
        address indexed strategy,
        uint256 performanceScore,
        uint256 benchmarkYield,
        uint256 timestamp
    );

    constructor(address _dataFeed) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
        dataFeed = IDataFeed(_dataFeed);
    }

    function updateMetrics(address strategy) external onlyRole(VERIFIER_ROLE) whenNotPaused {
        require(
            block.timestamp >= strategyMetrics[strategy].lastUpdateTime + UPDATE_INTERVAL,
            "Update interval not elapsed"
        );

        // Collect historical data
        uint256 startTime = block.timestamp.sub(MINIMUM_HISTORY_PERIOD);
        uint256[] memory events = dataFeed.getDepositWithdrawalEvents(startTime, block.timestamp);

        // Calculate total yield and volatility
        (uint256 totalYield, uint256 volatility) = calculateYieldMetrics(startTime, block.timestamp);

        // Calculate performance score (0-100)
        uint256 performanceScore = calculatePerformanceScore(totalYield, volatility, events);

        // Update benchmark yield using exponential moving average
        uint256 newBenchmarkYield = updateBenchmarkYield(
            strategy,
            totalYield,
            strategyMetrics[strategy].benchmarkYield
        );

        // Update strategy metrics
        strategyMetrics[strategy] = StrategyMetrics({
            performanceScore: performanceScore,
            benchmarkYield: newBenchmarkYield,
            lastUpdateTime: block.timestamp,
            totalYield: totalYield,
            volatility: volatility
        });

        emit MetricsUpdated(strategy, performanceScore, newBenchmarkYield, block.timestamp);
    }

    function calculateYieldMetrics(uint256 startTime, uint256 endTime)
        private
        view
        returns (uint256 totalYield, uint256 volatility)
    {
        uint256 samples = 0;
        uint256 sumYield = 0;
        uint256 sumSquaredDiff = 0;
        uint256 prevYield = 0;

        for (uint256 time = startTime; time <= endTime; time += 1 days) {
            uint256 dailyYield = dataFeed.getHistoricalYield(time);
            sumYield = sumYield.add(dailyYield);
            
            if (samples > 0) {
                uint256 diff = dailyYield > prevYield ?
                    dailyYield.sub(prevYield) :
                    prevYield.sub(dailyYield);
                sumSquaredDiff = sumSquaredDiff.add(diff.mul(diff));
            }
            
            prevYield = dailyYield;
            samples = samples.add(1);
        }

        totalYield = sumYield.div(samples);
        volatility = samples > 1 ? sqrt(sumSquaredDiff.div(samples.sub(1))) : 0;
    }

    function calculatePerformanceScore(
        uint256 totalYield,
        uint256 volatility,
        uint256[] memory events
    ) private pure returns (uint256) {
        // Base score from yield (60% weight)
        uint256 yieldScore = totalYield.mul(60);

        // Volatility penalty (25% weight)
        uint256 volatilityScore = volatility == 0 ? 25 : 25.mul(1e18).div(volatility.add(1e18));

        // Efficiency score based on events (15% weight)
        uint256 efficiencyScore = calculateEfficiencyScore(events);

        return yieldScore.add(volatilityScore).add(efficiencyScore);
    }

    function calculateEfficiencyScore(uint256[] memory events) private pure returns (uint256) {
        if (events.length == 0) return 15; // Maximum efficiency if no rebalancing needed
        
        // Penalize score based on number of rebalancing events
        uint256 penalty = events.length > 30 ? 15 : events.length.mul(15).div(30);
        return 15.sub(penalty);
    }

    function updateBenchmarkYield(
        address strategy,
        uint256 newYield,
        uint256 oldBenchmark
    ) private pure returns (uint256) {
        if (oldBenchmark == 0) return newYield;
        
        // Use exponential moving average with 0.1 smoothing factor
        return (newYield.mul(1).add(oldBenchmark.mul(9))).div(10);
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) private pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // Admin functions
    function setDataFeed(address _dataFeed) external onlyRole(DEFAULT_ADMIN_ROLE) {
        dataFeed = IDataFeed(_dataFeed);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}