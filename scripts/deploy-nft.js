const hre = require("hardhat");

async function main() {
  const ContractF = await hre.ethers.getContractFactory("NFT_Tree");
  const contr = await ContractF.deploy(
    hre.network.config.wormholeRelayer
  );

  await contr.deployed();

  console.log(
    "NFT_Tree deployed to: %saddress/%s",
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
