//Pancake deployment script on hardhat
const hre = require("hardhat");

async function main() {
  // eslint-disable-next-line no-undef
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with the account: ${deployer.address}`);

  const thousand = ethers.utils.parseUnits("1000", "wei")
  const hundredthousand = ethers.utils.parseUnits("1000000", "wei")
  const lpSupply = ethers.utils.parseUnits("689895", "wei")
  const million = ethers.utils.parseUnits("1000000", "wei")
  const quad = ethers.utils.parseUnits("1000000000000000", "wei")

  const BNB = await hre.ethers.getContractFactory("BNB");
  const bnb = await BNB.deploy("BNB", "BNB", thousand);
  await bnb.deployed();
  console.log("BNB deployed to:", bnb.address.toString());

  const BABYDOGE = await hre.ethers.getContractFactory("BABYDOGE");
  const babydoge = await BABYDOGE.deploy("BABYDOGE", "BABYDOGE", quad);
  await babydoge.deployed();
  console.log("BNB deployed to:", babydoge.address.toString());

  const USDT = await hre.ethers.getContractFactory("USDT");
  const usdt = await USDT.deploy("USDT", "USDT", million);
  await usdt.deployed();
  console.log("BNB deployed to:", usdt.address.toString());

  const FAKELP = await hre.ethers.getContractFactory("FAKELP");
  const fakelp = await FAKELP.deploy("FAKELP", "FAKELP", lpSupply);
  await fakelp.deployed();
  console.log("BNB deployed to:", fakelp.address.toString());

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});