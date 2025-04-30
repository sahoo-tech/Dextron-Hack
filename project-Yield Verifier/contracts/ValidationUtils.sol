// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ValidationUtils {
    /// @notice Validates timestamp ranges and data array lengths
    /// @param timestamps Array of timestamps to validate
    /// @param dataPoints Array of corresponding data points
    /// @param minDataPoints Minimum required number of data points
    /// @param maxTimeGap Maximum allowed gap between consecutive timestamps
    function validateTimeSeriesData(
        uint256[] memory timestamps,
        uint256[] memory dataPoints,
        uint256 minDataPoints,
        uint256 maxTimeGap
    ) internal pure {
        require(timestamps.length == dataPoints.length, "Array length mismatch");
        require(timestamps.length >= minDataPoints, "Insufficient data points");
        
        for (uint256 i = 1; i < timestamps.length; i++) {
            require(timestamps[i] > timestamps[i-1], "Timestamps not in ascending order");
            require(
                timestamps[i] - timestamps[i-1] <= maxTimeGap,
                "Time gap too large between data points"
            );
        }
    }

    /// @notice Validates yield rates are within acceptable bounds
    /// @param yieldRates Array of yield rates to validate
    /// @param maxYieldRate Maximum acceptable yield rate
    function validateYieldRates(
        uint256[] memory yieldRates,
        uint256 maxYieldRate
    ) internal pure {
        for (uint256 i = 0; i < yieldRates.length; i++) {
            require(yieldRates[i] <= maxYieldRate, "Yield rate exceeds maximum");
        }
    }

    /// @notice Validates utilization ratios are within acceptable range
    /// @param utilizationRatios Array of utilization ratios to validate
    function validateUtilizationRatios(
        uint256[] memory utilizationRatios
    ) internal pure {
        for (uint256 i = 0; i < utilizationRatios.length; i++) {
            require(
                utilizationRatios[i] <= 100,
                "Utilization ratio must be <= 100"
            );
        }
    }

    /// @notice Validates regression parameters are meaningful
    /// @param slope Calculated regression slope
    /// @param intercept Calculated regression intercept
    /// @param maxSlope Maximum acceptable absolute slope value
    function validateRegressionParams(
        uint256 slope,
        uint256 intercept,
        uint256 maxSlope
    ) internal pure {
        require(slope <= maxSlope, "Regression slope too steep");
        require(intercept > 0, "Invalid regression intercept");
    }
}