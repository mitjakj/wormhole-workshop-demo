// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.21;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./wormhole/IWormholeRelayer.sol";
import "./wormhole/IWormholeReceiver.sol";

contract HUB is IWormholeReceiver, Ownable {

    /**
     * @dev wormhole relayer which manages crosschain communication
     */
    IWormholeRelayer public wormholeRelayer;

    address public aCO2Token;

    mapping(uint16 => mapping(address => bool)) public whitelisted; // chainId => NFT_Tree address => true/false

    mapping(uint16 => mapping(address => mapping(uint256 => address))) public owners; // chainId => NFT_Tree address => tokenId => owner address

    /**
    * @dev Events
    */
    event WormHoleReceive(uint16 chainId, address relayer, address vault, bytes payload);

    constructor(
        address _wormholeRelayer
    ) Ownable(msg.sender) {
        wormholeRelayer = IWormholeRelayer(_wormholeRelayer);
    }

    function receiveWormholeMessages(
        bytes memory payload,
        bytes[] memory, // additionalVaas
        bytes32 sourceAddress,
        uint16 sourceChain,
        bytes32 // deliveryHash
    ) public payable override {
        require(msg.sender == address(wormholeRelayer), "Only relayer allowed");

        address sourceAddr = fromWormholeFormat(sourceAddress);

        require(
            whitelisted[sourceChain][sourceAddr],
            "Unauthorized"
        );

        (
            uint8 mode,
            address owner,
            uint256 timestamp,
            uint256[] memory ids
        ) = abi.decode(
            payload, 
            (
                uint8,
                address,
                uint256,
                uint256[]
            )
        );

        require(mode == 1 || mode == 2, "Invalid mode");


        // Save previous owner in case of transfer
        address previousOwner = owners[sourceChain][sourceAddr][ids[0]];

        // Save owner for each id
        for (uint256 i = 0; i < ids.length; i++) {
            owners[sourceChain][sourceAddr][ids[i]] = owner;
        }

        if (mode == 1) {
            // MINT

            // Do nothing
            // Do nothing

        } else if (mode == 2) {
            // TRANSFER

            // Execute 2nd hop -- mint tokens on Base
            uint256[] memory amounts = new uint256[](ids.length);
            for(uint256 i=0; i<ids.length; i++) {
                amounts[i] = 10; // 10 aCO2 tokens
            }

            bytes memory payload = abi.encode(
                previousOwner,
                ids,
                amounts
            );

            uint16 targetChain = 10004; // Base sepolia
            uint256 receiverValue = 0; // Can be left 0, since we don't need an airdrop of gas token on destination contract
            uint256 gasLimit = 500_000;

            (uint256 cost,) = wormholeRelayer.quoteEVMDeliveryPrice(targetChain, receiverValue, gasLimit);
            require(msg.value == cost, "crosschain fee mismatch");

            // send data to base
            wormholeRelayer.sendPayloadToEvm{value: cost}(
                targetChain,
                aCO2Token,
                payload, // payload
                receiverValue,
                gasLimit,
                targetChain, // refundChainId -> 10004 = Base sepolia
                msg.sender // refundAddress
            ); 

        }

        emit WormHoleReceive(sourceChain, msg.sender, fromWormholeFormat(sourceAddress), payload);
    }

    /**
     * @dev Convert bytes32 to address 
     */
    function fromWormholeFormat(bytes32 whFormatAddress) public pure returns (address) {
        if (uint256(whFormatAddress) >> 160 != 0) {
            revert NotAnEvmAddress(whFormatAddress);
        }
        return address(uint160(uint256(whFormatAddress)));
    }

    function setACO2Token(address _aco2Token) public onlyOwner {
        aCO2Token = _aco2Token;
    }

    function whitelist(uint16 sourceChain, address sourceAddr) public onlyOwner {
        whitelisted[sourceChain][sourceAddr] = true;
    }
}
