// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/utils/Base64.sol";
import "@lukso/LSP8IdentifiableDigitalAsset/presets/LSP8Mintable.sol";
import "@lukso/LSP8IdentifiableDigitalAsset/LSP8Constants.sol"; // Import LSP8 constants
import "@lukso/LSP4DigitalAssetMetadata/LSP4Constants.sol"; // Import LSP4 constants

contract CategoryGuessedNFT is LSP8Mintable {
    constructor(
        address contractOwner
    )
        LSP8Mintable(
            "Category Guessed NFT",
            "CGNFT",
            contractOwner,
            _LSP8_TOKENID_TYPE_NUMBER
        )
    {}

    function mintCategoryGuessedNFT(
        address winner,
        string memory category,
        string memory svg
    ) public onlyOwner {
        bytes32 tokenId = keccak256(
            abi.encodePacked(winner, category, block.timestamp)
        );
        _mint(winner, tokenId, true, "");

        // Encode SVG to Base64
        string memory encodedSVG = Base64.encode(bytes(svg));

        // Construct the data URI
        string memory imageURI = string(
            abi.encodePacked("data:image/svg+xml;base64,", encodedSVG)
        );

        // Construct metadata JSON
        string memory metadata = string(
            abi.encodePacked(
                '{"LSP4Metadata": {"name": "',
                category,
                '", "description": "An NFT representing the category winner',
                category,
                '", "image": "',
                imageURI,
                '"}}'
            )
        );

        // Set the LSP4 metadata
        setData(_LSP4_METADATA_KEY, bytes(metadata));
    }
}
