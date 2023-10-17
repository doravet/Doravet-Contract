import { ethers } from "hardhat";

async function main() {
  const Vote = await ethers.deployContract("Vote");
  
  await Vote.waitForDeployment();

  console.log(`Vote   deployed to ${Vote.target}` );

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
