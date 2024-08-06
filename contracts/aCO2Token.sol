// SPDX-License-Identifier: Unlicense

pragma solidity 0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./wormhole/IWormholeRelayer.sol";
import "./wormhole/IWormholeReceiver.sol";

contract aCO2Token is IWormholeReceiver, ERC1155, Ownable {

    string public name = "aCO2 Token";
    string public symbol = "aCO2";

    /**
     * @dev wormhole relayer which manages crosschain communication
     */
    IWormholeRelayer public wormholeRelayer;

    address public hubAddress;

    /**
    * @dev Events
    */
    event WormHoleReceive(uint16 chainId, address relayer, address vault, bytes payload);

    constructor(
        address _wormholeRelayer
    ) ERC1155("https://www.example.com/") Ownable(msg.sender) {
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
            sourceAddr == hubAddress,
            "Unauthorized"
        );

        (
            address user,
            uint256[] memory ids,
            uint256[] memory amounts
        ) = abi.decode(
            payload, 
            (
                address,
                uint256[],
                uint256[]
            )
        );

        for(uint256 i=0; i < ids.length; i++) {
            _mint(user, ids[i], amounts[i], "");
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

    function setHubAddress(address _hubAddress) public onlyOwner {
        hubAddress = _hubAddress;
    }
}
