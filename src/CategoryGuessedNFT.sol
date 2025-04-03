// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@lukso/LSP8IdentifiableDigitalAsset/presets/LSP8Mintable.sol";
import "@lukso/LSP8IdentifiableDigitalAsset/LSP8Constants.sol"; // Import LSP8 constants

contract CategoryGuessedNFT is LSP8Mintable {
    constructor(
        address contractOwner
    )
        LSP8Mintable(
            "Category Guessed NFT",
            "CGNFT",
            contractOwner,
            _LSP8_TOKENID_TYPE_NUMBER // Only LSP8 token ID format is required
        )
    {}

    function mintCategoryGuessedNFT(
        address winner,
        string memory category
    ) public onlyOwner {
        bytes32 tokenId = keccak256(
            abi.encodePacked(winner, category, block.timestamp)
        );
        _mint(winner, tokenId, true, "");
    }
}
