const { ethers } = require("hardhat");

async function main() {
  const PollenNft = await ethers.getContractFactory("PollenNft");
  const pollenNft = await upgrades.deployProxy(PollenNft, [], {
    initializer: "initialize",
  });

  await pollenNft.deployed();

  console.log("PollenNft deployed to:", pollenNft.address);
}

main().catch((error) => {
  console.error(error);
});
