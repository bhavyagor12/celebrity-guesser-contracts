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

        address deployer = vm.addr(deployerPrivateKey);

        CategoryGuessedNFT nftContract = new CategoryGuessedNFT(deployer);

        GuessTheCharacter guessTheCharacterContract = new GuessTheCharacter(
            payable(address(nftContract))
        );

        vm.stopBroadcast(); // End previous broadcast
        vm.startBroadcast(deployerPrivateKey); // Restart with deployer

        nftContract.transferOwnership(address(guessTheCharacterContract));

        vm.stopBroadcast();
    }
}
