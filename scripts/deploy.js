const hre = require("hardhat");

async function main() {
  // Deploy the HelloWorld contract
  const helloWorld = await hre.ethers.deployContract("HelloWorld", ["Nyc"]);

  // Wait for the contract to be deployed
  await helloWorld.waitForDeployment();

  console.log("HelloWorld deployed to:", helloWorld.target);

  // Wait for a few time before verifying, to make sure the contract is indexed by Etherscan
  console.log("Waiting for a few time before verifying...");
  await new Promise((resolve) => setTimeout(resolve, 30000)); // waiting for 30 seconds

  // Verify the contract on Etherscan
  await hre.run("verify:verify", {
    address: helloWorld.target,
    constructorArguments: ["YourNameHere"],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/deploy.js --network sepolia
