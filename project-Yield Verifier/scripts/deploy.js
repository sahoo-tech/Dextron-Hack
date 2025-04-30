const hre = require("hardhat");

async function validateDeployment(contract, name) {
  if (!contract.address) {
    throw new Error(`${name} deployment failed`);
  }
  console.log(`${name} deployed to:`, contract.address);
  return contract;
}

async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("\nStarting deployment with account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy DataFeed contract first
  try {
    const DataFeed = await hre.ethers.getContractFactory("DataFeed");
    // Replace with actual Chainlink oracle address for the network
    const mockOracleAddress = "0x0000000000000000000000000000000000000000";
    const dataFeed = await validateDeployment(
      await DataFeed.deploy(mockOracleAddress),
      "DataFeed"
    );

    // Deploy YieldVerifier contract
    const YieldVerifier = await hre.ethers.getContractFactory("YieldVerifier");
    const verifier = await validateDeployment(
      await YieldVerifier.deploy(dataFeed.address),
      "YieldVerifier"
    );

    // Grant roles
    const VERIFIER_ROLE = await verifier.VERIFIER_ROLE();
    const ORACLE_ROLE = await dataFeed.ORACLE_ROLE();

    // Grant roles to deployer for initial setup
    await (await verifier.grantRole(VERIFIER_ROLE, deployer.address)).wait();
    await (await dataFeed.grantRole(ORACLE_ROLE, deployer.address)).wait();
      console.log("\nRoles successfully granted to deployer");

    console.log("\nDeployment complete! Contract addresses:");
    console.log("DataFeed:", dataFeed.address);
    console.log("YieldVerifier:", verifier.address);
  } catch (error) {
    console.error("\nDeployment failed:", error.message || error);
    process.exit(1);
  }

main().then(() => process.exit(0))
  .catch((error) => {
    console.error("\nDeployment failed:", error.message || error);
    process.exit(1);
  });}
