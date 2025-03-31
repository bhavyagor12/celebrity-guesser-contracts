// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "src/GuessTheCharacter.sol";

contract GuessTheCharacterTest is Test {
    GuessTheCharacter game;
    address player = address(0x123);
    address owner = address(this);

    function setUp() public {
        game = new GuessTheCharacter();
    }

    function testStartGame() public {
        vm.deal(player, 1 ether);
        vm.prank(player);
        game.startGame{value: 0.001 ether}(GuessTheCharacter.Difficulty.Easy);

        (
            address p,
            GuessTheCharacter.Difficulty d,
            uint256 fee,
            bool isActive
        ) = game.activeGames(player);
        assertEq(p, player);
        assertEq(uint256(d), uint256(GuessTheCharacter.Difficulty.Easy));
        assertEq(fee, 0.001 ether);
        assertTrue(isActive);
    }

    function testCannotStartGameWithoutFee() public {
        vm.prank(player);
        vm.expectRevert("Insufficient entry fee");
        game.startGame{value: 0}(GuessTheCharacter.Difficulty.Medium);
    }

    function testResolveGameWin() public {
        vm.deal(player, 1 ether);
        vm.prank(player);
        game.startGame{value: 0.001 ether}(GuessTheCharacter.Difficulty.Easy);

        vm.deal(address(game), 1 ether);
        vm.prank(owner);
        game.resolveGame(true);

        (address p, , , bool isActive) = game.activeGames(player);
        assertEq(p, address(0));
        assertFalse(isActive);
    }

    function testResolveGameLose() public {
        vm.deal(player, 1 ether);
        vm.prank(player);
        game.startGame{value: 0.001 ether}(GuessTheCharacter.Difficulty.Hard);

        vm.prank(owner);
        game.resolveGame(false);

        (address p, , , bool isActive) = game.activeGames(player);
        assertEq(p, address(0));
        assertFalse(isActive);
    }

    function testFundContract() public {
        vm.deal(owner, 10 ether);
        vm.prank(owner);
        game.fundContract{value: 5 ether}();
        assertEq(address(game).balance, 5 ether);
    }

    function testWithdrawFunds() public {
        vm.deal(owner, 10 ether);
        vm.prank(owner);
        game.fundContract{value: 5 ether}();

        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        game.withdrawFunds(2 ether);

        assertEq(owner.balance, ownerBalanceBefore + 2 ether);
        assertEq(address(game).balance, 3 ether);
    }
}
