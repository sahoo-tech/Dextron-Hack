import { ethers } from 'ethers';

export const CONTRACTS = {
  DataFeed: {
    address: '0x9A676e781A523b5d0C0e43731313A708CB607508',
    abi: [
      'function getHistoricalYield(uint256 timestamp) external view returns (uint256)',
      'function getDepositWithdrawalEvents(uint256 startTime, uint256 endTime) external view returns (uint256[] memory)',
      'function getLatestYieldRate() external view returns (uint256)',
      'event DataUpdated(uint256 indexed timestamp, uint256 yieldRate)',
      'event EventsRecorded(uint256 indexed timestamp, uint256[] events)',
      'error InvalidTimestamp(uint256 timestamp)',
      'error NoDataAvailable()'
    ]
  },
  YieldVerifier: {
    address: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
    abi: [
      'function updateMetrics(address strategy) external',
      'function strategyMetrics(address) external view returns (uint256 performanceScore, uint256 benchmarkYield, uint256 lastUpdateTime, uint256 totalYield, uint256 volatility)',
      'event MetricsUpdated(address indexed strategy, uint256 performanceScore, uint256 benchmarkYield, uint256 timestamp)',
      'error InvalidStrategy(address strategy)',
      'error UpdateInProgress()',
      'error InsufficientData()'
    ]
  }
};

export const getContract = (contractName, provider) => {
  const contract = CONTRACTS[contractName];
  if (!contract) throw new Error(`Contract ${contractName} not found`);
  
  try {
    return new ethers.Contract(
      contract.address,
      contract.abi,
      provider
    );
  } catch (error) {
    console.error(`Error initializing ${contractName} contract:`, error);
    throw new Error(`Failed to initialize contract: ${error.message}`);
  }
};