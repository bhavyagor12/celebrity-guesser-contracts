// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "src/CategoryGuessedNFT.sol";
import "src/GuessTheCharacter.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy CategoryGuessedNFT first
        CategoryGuessedNFT nftContract = new CategoryGuessedNFT(msg.sender);

        // Deploy GuessTheCharacter with the address of the NFT contract
        new GuessTheCharacter(payable(address(nftContract)));

        vm.stopBroadcast();
    }
}
