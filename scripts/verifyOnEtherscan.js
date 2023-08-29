// script to verify unverified contracts already deployed
const hre = require("hardhat");

async function main() {
  // Contract details
  const contractName = "HelloWorld"; // Change this to the name of your contract
  const contractAddress = ""; // Replace with your deployed contract address
  const constructorArguments = ["Nyc"]; // Replace with the arguments used in your contract's constructor

  // Verify the contract on Etherscan
  console.log(`Verifying ${contractName} at ${contractAddress}...`);
  await hre.run("verify:verify", {
    address: contractAddress,
    constructorArguments: constructorArguments,
  });

  console.log(`${contractName} verified successfully!`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

// npx hardhat run scripts/VerifyOnEtherscan.js --network sepolia
