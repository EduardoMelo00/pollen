const { ethers, upgrades } = require("hardhat");

async function main() {
  const Pollen = await ethers.getContractFactory("FAKEXRZ");

  const pollen = await Pollen.deploy();

  await pollen.deployed();

  console.log("Pollen deployed to:", pollen.address);
}

main().catch((error) => {
  console.error(error);
});

// async function main() {
//   const Pollen = await ethers.getContractFactory("Pollen")
//   console.log("Deploying Box, ProxyAdmin, and then Proxy...")
//   const proxy = await upgrades.deployProxy(Pollen, { initializer: 'Initiliazer' })
//   console.log("Proxy of Box deployed to:", proxy.address)
// }

// main()
//   .then(() => process.exit(0))
//   .catch(error => {
//       console.error(error)
//       process.exit(1)
//   })
