# Yield Verifier Algorithm Documentation

## Overview
The Yield Verifier Algorithm is a robust system for calculating performance scores and benchmark yields for various DeFi yield farming strategies. It implements role-based access control and uses The Graph protocol for historical data collection.

## Architecture

### System Overview
The system consists of multiple smart contracts and components that work together to provide accurate yield verification and performance scoring:

1. **YieldVerifier Contract**: Core verification engine that calculates performance metrics
2. **DataFeed Contract**: Oracle-integrated data provider that manages historical yield data
3. **TheGraphConsumer Contract**: Handles queries to The Graph protocol for historical data
4. **ValidationUtils Contract**: Provides common validation functions used across contracts

### Component Diagram
```
[Frontend] → [YieldVerifier] ←→ [DataFeed]
                    ↑               ↑
                    |               |
            [ValidationUtils]  [TheGraphConsumer]
```

### Smart Contracts

#### YieldVerifier.sol
- **Purpose**: Main contract for performance scoring and benchmark yield calculations
- **Key Features**:
  - Role-based access control (VERIFIER_ROLE)
  - Pausable functionality for emergency stops
  - Performance metrics calculation using weighted components:
    - Yield Weight: 60%
    - Volatility Weight: 25%
    - Efficiency Weight: 15%
  - Dynamic benchmark yield adjustment using regression analysis
  - Minimum 30 data points requirement
  - 180-day minimum history period
  - Daily update interval

#### DataFeed.sol
- **Purpose**: Oracle-integrated data management system
- **Key Features**:
  - Role-based access control (ORACLE_ROLE)
  - Chainlink oracle integration for real-time yield rates
  - Historical data storage and retrieval
  - Event tracking for deposits and withdrawals
  - Timestamp validation and data integrity checks

### Contract Interaction Flow
1. Frontend initiates verification request
2. YieldVerifier:
   - Validates inputs using ValidationUtils
   - Requests historical data from DataFeed
3. DataFeed:
   - Gets real-time data from Chainlink oracles
   - Gets historical data via TheGraphConsumer
4. YieldVerifier calculates performance metrics
5. Results are stored and events emitted for frontend updates

### Deployment Architecture
```
[Ethereum Mainnet]
   ├── YieldVerifier (verification logic)
   ├── DataFeed (data aggregation)
   ├── TheGraphConsumer (historical queries)
   └── ValidationUtils (shared utilities)
```

### Data Flow
1. Historical data collection (6+ months)
   - Daily yield rates
   - Deposit/withdrawal events
   - Strategy performance metrics

2. Performance Score Calculation
   - Components:
     - Total yield (60%)
     - Volatility measures (25%)
     - Efficiency metrics (15%)
   - Score range: 0-100

3. Benchmark Yield Determination
   - Uses regression analysis with 30-day window
   - Minimum 30 data points required
   - Dynamic adjustment using exponential moving average

## Implementation Details

### Data Collection
```solidity
function getHistoricalData(
    uint256 startTime,
    uint256 endTime
) external view returns (
    uint256[] memory timestamps,
    uint256[] memory yieldRates,
    uint256[] memory depositEvents,
    uint256[] memory withdrawalEvents,
    uint256[] memory utilizationRatios
)
```

### Performance Scoring
- Yield Weight: 60%
- Volatility Weight: 25%
- Efficiency Weight: 15%

### Benchmark Calculation
```solidity
function updateBenchmarkYield(
    address strategy,
    uint256 totalYield,
    uint256 currentBenchmark
) internal pure returns (uint256)
```

## Security Considerations
1. Role-based access control
   - Only designated verifiers can update metrics
   - Admin role for contract management

2. Data Validation
   - Minimum historical period: 180 days
   - Update interval: 1 day
   - Minimum data points: 30

## Integration
1. Deploy DataFeed contract
2. Deploy YieldVerifier with DataFeed address
3. Grant VERIFIER_ROLE to authorized addresses
4. Call updateMetrics() for strategy performance updates

## Assumptions
1. The Graph protocol provides reliable historical data
2. Yield rates are normalized to common decimals
3. Strategy addresses are valid and active
4. Network latency doesn't affect data retrieval

## Dependencies
- OpenZeppelin Contracts v4.x
  - AccessControl
  - Pausable
  - SafeMath
- The Graph Protocol integration
