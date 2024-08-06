// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./wormhole/IWormholeRelayer.sol";

contract NFT_Tree is ERC721Enumerable, Ownable {

    uint256 currId;

    /**
     * @dev wormhole relayer which manages crosschain communication
     */
    IWormholeRelayer public wormholeRelayer;

    address public hubAddress;

    constructor(
        address _wormholeRelayer
    ) ERC721("Workshop NFT", "W-NFT") Ownable(msg.sender) {
        
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    // public
    function mint(address user, uint256 quantity) external payable {

        uint256[] memory ids = new uint256[](quantity);
        for(uint256 i=0; i<quantity; i++) {
            currId++;
            _safeMint(user, currId);
            ids[i] = currId;
        }

        bytes memory payload = abi.encode(
            1, // 1 = mint, 2 = transfer
            user,
            block.timestamp,
            ids
        );

        uint16 targetChain = 16; // Moonbeam
        uint256 receiverValue = 0; // Can be left 0, since we don't need an airdrop of gas token on destination contract
        uint256 gasLimit = 500_000;

        (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);
        require(msg.value == cost, "crosschain fee mismatch");

        // send data to moonbeam
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            hubAddress,
            payload, // payload
            receiverValue,
            gasLimit,
            targetChain, // refundChainId -> 16 = Moonbeam
            msg.sender // refundAddress
        ); 
    }

    function transferFromPayable(address from, address to, uint256 tokenId, uint256 receiverValue) external payable {
        super.transferFrom(from, to, tokenId);

        // Crosschain call to HUB
        uint256[] memory ids = new uint256[](1);
        ids[0] = tokenId;

        bytes memory payload = abi.encode(
            2, // 1 = mint, 2 = transfer
            to,
            block.timestamp,
            ids
        );

        uint16 targetChain = 16; // Moonbeam
        uint256 gasLimit = 500_000;

        (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);
        require(msg.value == cost, "crosschain fee mismatch");

        // send data to moonbeam
        wormholeRelayer.sendPayloadToEvm{value: cost}(
            targetChain,
            hubAddress,
            payload, // payload
            receiverValue,
            gasLimit,
            targetChain, // refundChainId -> 16 = Moonbeam
            msg.sender // refundAddress
        ); 
    }

    function transferFrom(address from, address to, uint256 tokenId) public override(ERC721, IERC721) {
        revert("Unsupported");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721, IERC721) {
        revert("Unsupported");
    }

    function setHubAddress(address _hubAddress) public onlyOwner {
        hubAddress = _hubAddress;
    }
}
