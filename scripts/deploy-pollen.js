const { ethers } = require("hardhat");

async function main() {
  const Pollen = await ethers.getContractFactory("Pollen");
  const pollen = await Pollen.deploy();

  await pollen.deployed();

  console.log("Pollen deployed to:", pollen.address);
}

main().catch((error) => {
  console.error(error);
});
