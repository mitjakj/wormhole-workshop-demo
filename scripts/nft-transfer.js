const hre = require("hardhat");

const NFT_TREE_ADDRESS = "0x7eC34DC6f0F6C3939fbE1D0b1041746596495a60";

const moonbeamConfig = hre.userConfig.networks.moonbaseAlpha;
const moonbeamProvider = new hre.ethers.providers.JsonRpcProvider(moonbeamConfig.url);
const moonbeamOwner = new hre.ethers.Wallet(moonbeamConfig.accounts[0], moonbeamProvider);

async function main() {
  const owner = (await hre.ethers.getSigners())[0]; 

  const wormholeRelayer_MOONBEAM = new ethers.Contract(
    moonbeamConfig.wormholeRelayer, 
    ['function quoteEVMDeliveryPrice(uint16 targetChain, uint256 receiverValue, uint256 gasLimit) public view returns (uint256, uint256)'], 
    moonbeamOwner
  );

  const wormholeRelayer_CELO = new ethers.Contract(
    hre.network.config.wormholeRelayer, 
    ['function quoteEVMDeliveryPrice(uint16 targetChain, uint256 receiverValue, uint256 gasLimit) public view returns (uint256, uint256)'], 
    owner
  );

  const nftTree = await ethers.getContractAt("NFT_Tree", NFT_TREE_ADDRESS, owner);

  // Quote wormhole fee for hop2 crosschain call MOONBEAM > BASE
  const BASE_targetChain = 10004; // Base sepolia
  const BASE_receiverValue = 0;
  const BASE_gasLimit = 500000;
  const wormholeFee_hop2 = (await wormholeRelayer_MOONBEAM.quoteEVMDeliveryPrice(BASE_targetChain, BASE_receiverValue, BASE_gasLimit))[0];

  // Quote wormhole fee for crosschain call CELO > MOONBEAM
  const MOONBEAM_targetChain = 16; // Moonbase
  const MOONBEAM_receiverValue = wormholeFee_hop2;
  const MOONBEAM_gasLimit = 500000;
  const wormholeFee_hop1 = (await wormholeRelayer_CELO.quoteEVMDeliveryPrice(MOONBEAM_targetChain, MOONBEAM_receiverValue, MOONBEAM_gasLimit))[0];

  const transferTokenId = 2;
  const transferRecipient = "0x1F21f7A70997e3eC5FbD61C047A26Cdc88e7089B";

  const ownerOf = await nftTree.ownerOf(transferTokenId);
  if(ownerOf != owner.address) {
    console.log(`NFT ID: ${transferTokenId} not owned by ${owner.address}`);
    process.exit(0);
  }

  const tx = await nftTree.transferFromPayable(
    owner.address, 
    transferRecipient, 
    transferTokenId,
    wormholeFee_hop2, // whValue
    {value: wormholeFee_hop1}
  );

  await tx.wait();

  console.log(`hop 2 cost: ${ethers.utils.formatEther(wormholeFee_hop2)} GLMR`);
  console.log(`total cost: ${ethers.utils.formatEther(wormholeFee_hop1)} CELO`);
  console.log(`Transfer successful: ${hre.network.config.explorer}tx/${tx.hash}`);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
