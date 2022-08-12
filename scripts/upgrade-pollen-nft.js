const { ethers, upgrades } = require("hardhat");

const PROXY = "0xe8ADe587fad9dbE3808bD6986B26cb1B254Af9e7";

async function main() {
  const PollenNftV3 = await ethers.getContractFactory("PollenNftV3");
  console.log("Upgrading PollenNftV3...");
  await upgrades.upgradeProxy(PROXY, PollenNftV3);
  console.log("PollenNftV2 upgraded successfully");
}

main();
