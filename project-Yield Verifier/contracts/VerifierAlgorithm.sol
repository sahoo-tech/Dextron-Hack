// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./TheGraphDataFeed.sol";

interface IDataFeed {
    function getStrategyData(address strategy) external view returns (uint256[] memory timestamps, uint256[] memory yields);
}

contract YieldVerifier is AccessControl, Pausable {
    bytes32 public constant VERIFIER_ROLE = keccak256("VERIFIER_ROLE");

    // Minimum time period required for historical data (6 months)
    uint256 public constant MINIMUM_HISTORY_PERIOD = 180 days;
    uint256 public constant UPDATE_INTERVAL = 1 days;

    // Weights for performance score calculation
    uint256 private constant YIELD_WEIGHT = 60;
    uint256 private constant VOLATILITY_WEIGHT = 25;
    uint256 private constant EFFICIENCY_WEIGHT = 15;

    // Regression parameters
    uint256 private constant REGRESSION_WINDOW = 30 days;
    uint256 private constant MIN_DATA_POINTS = 30;

    struct StrategyMetrics {
        uint256 performanceScore;
        uint256 benchmarkYield;
        uint256 lastUpdateTime;
        uint256 totalYield;
        uint256 volatility;
        uint256 utilizationRatio;
        uint256 regressionSlope;
        uint256 regressionIntercept;
    }

    mapping(address => StrategyMetrics) public strategyMetrics;

    TheGraphDataFeed private dataFeed;

    event MetricsUpdated(
        address indexed strategy,
        uint256 performanceScore,
        uint256 benchmarkYield,
        uint256 timestamp,
        uint256 regressionSlope
    );

    constructor(address _dataFeed) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(VERIFIER_ROLE, msg.sender);
        dataFeed = TheGraphDataFeed(_dataFeed);
    }

    function updateMetrics(address strategy) external onlyRole(VERIFIER_ROLE) {
        require(
            block.timestamp >= strategyMetrics[strategy].lastUpdateTime + UPDATE_INTERVAL,
            "Update interval not elapsed"
        );

        // Collect historical data from The Graph
        uint256 startTime = block.timestamp - MINIMUM_HISTORY_PERIOD;
        (
            uint256[] memory timestamps,
            uint256[] memory yieldRates,
            uint256[] memory depositEvents,
            uint256[] memory withdrawalEvents,
            uint256[] memory utilizationRatios
        ) = dataFeed.getHistoricalData(startTime, block.timestamp);

        require(timestamps.length >= MIN_DATA_POINTS, "Insufficient historical data");

        // Calculate metrics using regression analysis
        (uint256 totalYield, uint256 volatility, uint256 avgUtilization) = calculateYieldMetrics(
            timestamps,
            yieldRates,
            utilizationRatios
        );

        // Calculate regression parameters for yield trend
        (uint256 slope, uint256 intercept) = calculateRegressionParameters(
            timestamps,
            yieldRates
        );

        // Calculate performance score using weighted components
        uint256 performanceScore = calculatePerformanceScore(
            totalYield,
            volatility,
            depositEvents,
            withdrawalEvents,
            avgUtilization
        );

        // Update benchmark yield using regression-based prediction
        uint256 newBenchmarkYield = updateBenchmarkYield(
            strategy,
            totalYield,
            slope,
            intercept
        );

        // Update strategy metrics
        strategyMetrics[strategy] = StrategyMetrics({
            performanceScore: performanceScore,
            benchmarkYield: newBenchmarkYield,
            lastUpdateTime: block.timestamp,
            totalYield: totalYield,
            volatility: volatility,
            utilizationRatio: avgUtilization,
            regressionSlope: slope,
            regressionIntercept: intercept
        });

        emit MetricsUpdated(strategy, performanceScore, newBenchmarkYield, block.timestamp, slope);
    }

    function calculateYieldMetrics(
        uint256[] memory timestamps,
        uint256[] memory yieldRates,
        uint256[] memory utilizationRatios
    )
        private
        pure
        returns (uint256 totalYield, uint256 volatility, uint256 avgUtilization)
    {
        require(timestamps.length > 0, "Empty data set");
        
        uint256 sumYield;
        uint256 sumUtilization;
        uint256 varianceSum;
        uint256 meanYield;
        
        // Calculate mean yield
        for (uint256 i = 0; i < yieldRates.length; i++) {
            sumYield += yieldRates[i];
            sumUtilization += utilizationRatios[i];
        }
        
        meanYield = sumYield / yieldRates.length;
        avgUtilization = sumUtilization / utilizationRatios.length;
        
        // Calculate volatility (standard deviation)
        for (uint256 i = 0; i < yieldRates.length; i++) {
            if (yieldRates[i] > meanYield) {
                varianceSum += (yieldRates[i] - meanYield) ** 2;
            } else {
                varianceSum += (meanYield - yieldRates[i]) ** 2;
            }
        }
        
        volatility = sqrt(varianceSum / yieldRates.length);
        totalYield = meanYield;
        
        return (totalYield, volatility, avgUtilization);
    }

    function calculateRegressionParameters(
        uint256[] memory timestamps,
        uint256[] memory yieldRates
    )
        private
        pure
        returns (uint256 slope, uint256 intercept)
    {
        require(timestamps.length >= MIN_DATA_POINTS, "Insufficient data points");

        uint256 n = timestamps.length;
        uint256 sumX;
        uint256 sumY;
        uint256 sumXY;
        uint256 sumXX;

        // Calculate sums for regression formula
        for (uint256 i = 0; i < n; i++) {
            sumX += timestamps[i];
            sumY += yieldRates[i];
            sumXY += timestamps[i] * yieldRates[i];
            sumXX += timestamps[i] * timestamps[i];
        }

        // Calculate slope and intercept
        // slope = (n*sumXY - sumX*sumY) / (n*sumXX - sumX*sumX)
        slope = ((n * sumXY) - (sumX * sumY)) / ((n * sumXX) - (sumX * sumX));
        // intercept = (sumY - slope*sumX) / n
        intercept = (sumY - (slope * sumX)) / n;

        return (slope, intercept);
    }

    function calculatePerformanceScore(
        uint256 totalYield,
        uint256 volatility,
        uint256[] memory depositEvents,
        uint256[] memory withdrawalEvents,
        uint256 utilizationRatio
    )
        private
        pure
        returns (uint256)
    {
        // Calculate yield component (60%)
        uint256 yieldScore = (totalYield * YIELD_WEIGHT) / 100;

        // Calculate volatility component (25%)
        // Lower volatility = higher score
        uint256 volatilityScore = volatility == 0 ? VOLATILITY_WEIGHT : (VOLATILITY_WEIGHT * 1e18) / volatility;

        // Calculate efficiency component (15%)
        uint256 eventCount = depositEvents.length + withdrawalEvents.length;
        uint256 efficiencyScore = calculateEfficiencyScore(eventCount, utilizationRatio);

        return yieldScore + volatilityScore + efficiencyScore;
    }

    function calculateEfficiencyScore(
        uint256 eventCount,
        uint256 utilizationRatio
    )
        private
        pure
        returns (uint256)
    {
        // Penalize if too many events (high gas costs) or low utilization
        uint256 eventPenalty = eventCount > 100 ? (eventCount - 100) / 10 : 0;
        uint256 baseScore = EFFICIENCY_WEIGHT;

        if (eventPenalty >= baseScore) {
            return 0;
        }

        uint256 score = baseScore - eventPenalty;
        return (score * utilizationRatio) / 100;
    }



    function updateBenchmarkYield(
        address strategy,
        uint256 totalYield,
        uint256 slope,
        uint256 intercept
    )
        private
        view
        returns (uint256)
    {
        // Use regression model to predict next period's yield
        uint256 nextPeriod = block.timestamp + UPDATE_INTERVAL;
        uint256 predictedYield = (slope * nextPeriod) + intercept;

        // Get current benchmark yield
        uint256 currentBenchmark = strategyMetrics[strategy].benchmarkYield;
        if (currentBenchmark == 0) {
            return predictedYield;
        }

        // Combine regression prediction with exponential moving average
        uint256 movingAvg = (totalYield + (currentBenchmark * 9)) / 10;
        
        // Final yield is weighted average of prediction and moving average (70-30 split)
        return ((predictedYield * 70) + (movingAvg * 30)) / 100;
    }

    // Helper function to calculate square root


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
        dataFeed = TheGraphDataFeed(_dataFeed);
    }

    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}