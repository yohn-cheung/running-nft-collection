// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");
require("dotenv").config({ path: ".env" });
const { WHITELIST_CONTRACT_ADDRESS, METADATA_URL } = require("../constants");


async function main() {
  const whitelistContract = WHITELIST_CONTRACT_ADDRESS;
  const metadataURL = METADATA_URL;

  const runningDevsContract = await hre.ethers.getContractFactory("RunningDevs");

  const deployedRunningDevsContract = await runningDevsContract.deploy(metadataURL, whitelistContract)

  console.log(
    "Running Devs Contract Address:",
    deployedRunningDevsContract.address
  );
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });