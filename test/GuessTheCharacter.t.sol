// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {GuessTheCharacter} from "../src/GuessTheCharacter.sol";
import {CategoryGuessedNFT} from "../src/CategoryGuessedNFT.sol";

contract GuessTheCharacterTest is Test {
    GuessTheCharacter guessTheCharacter;
    CategoryGuessedNFT categoryGuessedNFT;

    address owner = address(0x123);
    address player = address(0x456);

    uint256 baseEntryFee = 0.001 ether;
    string category = "Fantasy";

    function setUp() public {
        vm.deal(owner, 10 ether);
        vm.deal(player, 10 ether);

        // Deploy the NFT contract as owner
        vm.prank(owner);
        categoryGuessedNFT = new CategoryGuessedNFT(owner);

        // Deploy GuessTheCharacter
        vm.prank(owner);
        guessTheCharacter = new GuessTheCharacter(
            payable(address(categoryGuessedNFT))
        );

        // Transfer ownership of NFT contract to GuessTheCharacter
        vm.prank(owner);
        categoryGuessedNFT.transferOwnership(address(guessTheCharacter));

        // Fund the contract
        vm.deal(address(guessTheCharacter), 10 ether);

        // Verify ownership
        assertEq(
            categoryGuessedNFT.owner(),
            address(guessTheCharacter),
            "NFT contract owner should be GuessTheCharacter"
        );
    }

    function testStartGame() public {
        vm.prank(player);
        guessTheCharacter.startGame{value: baseEntryFee}();

        (
            address storedPlayer,
            uint256 storedFee,
            bool isActive
        ) = guessTheCharacter.games(player);
        assertEq(storedPlayer, player);
        assertEq(storedFee, baseEntryFee);
        assertTrue(isActive);
    }

    function testResolveGameWin() public {
        vm.prank(player);
        guessTheCharacter.startGame{value: baseEntryFee}();

        assertEq(
            guessTheCharacter.owner(),
            owner,
            "Contract owner should match test owner"
        );
        console.log("Contract owner: %s", guessTheCharacter.owner());
        // Prank as owner before calling resolveGame
        vm.prank(owner);
        guessTheCharacter.resolveGame(player, true, category);

        // Check if the game is marked inactive
        (, , bool isActive) = guessTheCharacter.games(player);
        assertFalse(isActive);
    }

    function testResolveGameLoss() public {
        vm.prank(player);
        guessTheCharacter.startGame{value: baseEntryFee}();

        vm.prank(owner);
        guessTheCharacter.resolveGame(player, false, category);

        (, , bool isActive) = guessTheCharacter.games(player);
        assertFalse(isActive);
    }

    function testOnlyOwnerCanResolve() public {
        vm.prank(player);
        guessTheCharacter.startGame{value: baseEntryFee}();

        vm.prank(player);
        vm.expectRevert("Not authorized");
        guessTheCharacter.resolveGame(player, true, category);
    }

    function testWithdrawFunds() public {
        vm.deal(address(guessTheCharacter), 1 ether);

        uint256 ownerBalanceBefore = owner.balance;
        uint256 withdrawAmount = 0.5 ether;

        vm.prank(owner);
        guessTheCharacter.withdrawFunds(withdrawAmount);

        uint256 ownerBalanceAfter = owner.balance;
        assertEq(ownerBalanceAfter, ownerBalanceBefore + withdrawAmount);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.deal(address(guessTheCharacter), 1 ether);

        vm.prank(player);
        vm.expectRevert("Not authorized");
        guessTheCharacter.withdrawFunds(0.5 ether);
    }
}
