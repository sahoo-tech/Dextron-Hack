const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("YieldVerifier", function () {
  let YieldVerifier, DataFeed;
  let verifier, dataFeed;
  let owner, verifierRole, strategy;
  
  beforeEach(async function () {
    [owner, verifierRole, strategy] = await ethers.getSigners();
    
    // Deploy DataFeed contract
    DataFeed = await ethers.getContractFactory("DataFeed");
    dataFeed = await DataFeed.deploy("0x0000000000000000000000000000000000000000"); // Mock oracle address
    await dataFeed.deployed();
    
    // Deploy YieldVerifier contract
    YieldVerifier = await ethers.getContractFactory("YieldVerifier");
    verifier = await YieldVerifier.deploy(dataFeed.address);
    await verifier.deployed();
    
    // Grant roles
    await verifier.grantRole(await verifier.VERIFIER_ROLE(), verifierRole.address);
    await dataFeed.grantRole(await dataFeed.ORACLE_ROLE(), owner.address);
  });

  describe("Initialization", function () {
    it("Should set the correct data feed address", async function () {
      expect(await verifier.dataFeed()).to.equal(dataFeed.address);
    });

    it("Should grant VERIFIER_ROLE to specified address", async function () {
      expect(await verifier.hasRole(await verifier.VERIFIER_ROLE(), verifierRole.address)).to.be.true;
    });
  });

  describe("Metrics Calculation", function () {
    beforeEach(async function () {
      // Populate test data
      const now = Math.floor(Date.now() / 1000);
      for (let i = 0; i < 31; i++) {
        const timestamp = now - (i * 86400); // Daily data points
        await dataFeed.updateYieldData(timestamp, ethers.utils.parseEther("0.1")); // 10% APY
        await dataFeed.recordEvents(timestamp, [ethers.utils.parseEther("100")]); // Mock events
      }
    });

    it("Should calculate performance score correctly", async function () {
      await verifier.connect(verifierRole).updateMetrics(strategy.address);
      const metrics = await verifier.strategyMetrics(strategy.address);
      
      expect(metrics.performanceScore).to.be.gt(0);
      expect(metrics.benchmarkYield).to.be.gt(0);
      expect(metrics.lastUpdateTime).to.be.gt(0);
    });

    it("Should handle volatility in yield rates", async function () {
      const now = Math.floor(Date.now() / 1000);
      // Add some volatile data points
      await dataFeed.updateYieldData(now, ethers.utils.parseEther("0.15")); // 15% APY
      await dataFeed.updateYieldData(now - 86400, ethers.utils.parseEther("0.05")); // 5% APY
      
      await verifier.connect(verifierRole).updateMetrics(strategy.address);
      const metrics = await verifier.strategyMetrics(strategy.address);
      
      expect(metrics.volatility).to.be.gt(0);
    });

    it("Should update benchmark yield based on regression", async function () {
      await verifier.connect(verifierRole).updateMetrics(strategy.address);
      const metrics = await verifier.strategyMetrics(strategy.address);
      
      expect(metrics.regressionSlope).to.not.equal(0);
      expect(metrics.regressionIntercept).to.not.equal(0);
    });
  });

  describe("Access Control", function () {
    it("Should revert when non-verifier tries to update metrics", async function () {
      await expect(
        verifier.connect(strategy).updateMetrics(strategy.address)
      ).to.be.revertedWith("AccessControl");
    });

    it("Should enforce update interval", async function () {
      await verifier.connect(verifierRole).updateMetrics(strategy.address);
      await expect(
        verifier.connect(verifierRole).updateMetrics(strategy.address)
      ).to.be.revertedWith("Update interval not elapsed");
    });
  });

  describe("Error Handling", function () {
    it("Should revert with insufficient historical data", async function () {
      await expect(
        verifier.connect(verifierRole).updateMetrics(strategy.address)
      ).to.be.revertedWith("Insufficient historical data");
    });

    it("Should handle empty data sets gracefully", async function () {
      const now = Math.floor(Date.now() / 1000);
      await dataFeed.updateYieldData(now, 0);
      
      await expect(
        verifier.connect(verifierRole).updateMetrics(strategy.address)
      ).to.be.revertedWith("Empty data set");
    });
  });
});