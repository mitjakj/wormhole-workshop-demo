const hre = require("hardhat");

const NFT_TREE_ADDRESS = "0xAdB4f214Ee43866711e5De6dA0CEc8AedF8FC636";

async function main() {
  const owner = (await hre.ethers.getSigners())[0]; 

  const wormholeRelayer = new ethers.Contract(
    hre.network.config.wormholeRelayer, 
    ['function quoteEVMDeliveryPrice(uint16 targetChain, uint256 receiverValue, uint256 gasLimit) public view returns (uint256, uint256)'], 
    owner
  );

  const nftTree = await ethers.getContractAt("NFT_Tree", NFT_TREE_ADDRESS, owner);

  const quantity = 1;
  const targetChain = 16; // Moonbeam
  const receiverValue = 0;
  const gasLimit = 500000;

  // Quote wormhole fee for crosschain call CELO > MOONBEAM
  const wormholeFee = (await wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit))[0];

  const tx = await nftTree.mint(
    owner.address, 
    quantity, 
    {value: wormholeFee}
  );

  await tx.wait();

  console.log(`Mint successful: ${hre.network.config.explorer}tx/${tx.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
