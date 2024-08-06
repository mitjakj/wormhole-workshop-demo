const hre = require("hardhat");

async function main() {
  const ContractF = await hre.ethers.getContractFactory("HUB");
  const contr = await ContractF.deploy(
    hre.network.config.wormholeRelayer
  );

  await contr.deployed();

  console.log(
    "HUB deployed to: %saddress/%s",
    hre.network.config.explorer,
    contr.address
  );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
