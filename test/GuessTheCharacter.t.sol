// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GuessTheCharacter.sol";

contract GuessTheCharacterTest is Test {
    GuessTheCharacter public game;
    address public owner;
    address public player1;
    address public player2;

    // Base entry fee in wei (0.001 ether)
    uint256 public constant BASE_ENTRY_FEE = 1_000_000_000_000_000;

    function setUp() public {
        owner = address(this);
        player1 = address(0x1);
        player2 = address(0x2);

        // Deploy the contract
        game = new GuessTheCharacter();

        // Fund the contract to have enough balance for rewards
        vm.deal(owner, 10 ether);
        game.fundContract{value: 5 ether}();

        // Fund players
        vm.deal(player1, 1 ether);
        vm.deal(player2, 1 ether);
    }

    function testInitialization() public view {
        assertEq(game.owner(), owner);
        assertEq(game.baseEntryFee(), BASE_ENTRY_FEE);
        assertEq(
            uint256(game.rewardMultipliers(GuessTheCharacter.Difficulty.Easy)),
            150
        );
        assertEq(
            uint256(
                game.rewardMultipliers(GuessTheCharacter.Difficulty.Medium)
            ),
            125
        );
        assertEq(
            uint256(game.rewardMultipliers(GuessTheCharacter.Difficulty.Hard)),
            111
        );
    }

    // Test starting a game
    function testStartGame() public {
        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        // When accessing the games mapping externally, it returns a tuple
        (
            uint256 id,
            address playerAddr,
            GuessTheCharacter.Difficulty difficulty,
            uint256 entryFee,
            bool isActive
        ) = game.games(gameId);

        assertEq(id, gameId);
        assertEq(playerAddr, player1);
        assertEq(
            uint256(difficulty),
            uint256(GuessTheCharacter.Difficulty.Easy)
        );
        assertEq(entryFee, BASE_ENTRY_FEE);
        assertTrue(isActive);

        // Check that the game appears in player's active games
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 1);
        assertEq(activeGames[0], gameId);
    }

    // Test starting multiple games by the same player
    function testStartMultipleGames() public {
        vm.startPrank(player1);

        uint256 gameId1 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        uint256 gameId2 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Medium
        );
        uint256 gameId3 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Hard
        );

        vm.stopPrank();

        // Check all games exist and are active
        (, , , , bool isActive1) = game.games(gameId1);
        (, , , , bool isActive2) = game.games(gameId2);
        (, , , , bool isActive3) = game.games(gameId3);

        assertTrue(isActive1);
        assertTrue(isActive2);
        assertTrue(isActive3);

        // Check player has three active games
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 3);
    }

    // Test starting a game with insufficient funds
    function testStartGameInsufficientFunds() public {
        vm.startPrank(player1);

        // Try to start with less than required entry fee
        vm.expectRevert("Insufficient entry fee");
        game.startGame{value: BASE_ENTRY_FEE - 1}(
            GuessTheCharacter.Difficulty.Easy
        );

        vm.stopPrank();
    }

    // Test resolving a game with a win
    function testResolveGameWin() public {
        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        uint256 initialBalance = player1.balance;

        // Owner resolves the game as a win
        game.resolveGame(gameId, true);

        // Calculate expected reward (1.5x for Easy)
        uint256 expectedReward = (BASE_ENTRY_FEE * 150) / 100;

        // Check player received reward
        assertEq(player1.balance, initialBalance + expectedReward);

        // Check game is marked as inactive
        (, , , , bool isActive) = game.games(gameId);
        assertFalse(isActive);

        // Check active games list is empty
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 0);
    }

    // Test resolving a game with a loss
    function testResolveGameLoss() public {
        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        uint256 initialBalance = player1.balance;

        // Owner resolves the game as a loss
        game.resolveGame(gameId, false);

        // Check player balance didn't change
        assertEq(player1.balance, initialBalance);

        // Check game is marked as inactive
        (, , , , bool isActive) = game.games(gameId);
        assertFalse(isActive);
    }

    // Test resolving a non-existent game
    function testResolveNonExistentGame() public {
        // Try to resolve a game that doesn't exist
        vm.expectRevert("Game does not exist");
        game.resolveGame(999, true);
    }

    // Test resolving an inactive game
    function testResolveInactiveGame() public {
        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        // Resolve the game once
        game.resolveGame(gameId, true);

        // Try to resolve it again
        vm.expectRevert("Game is not active");
        game.resolveGame(gameId, true);
    }

    // Test resolving a game by non-owner
    function testResolveGameNonOwner() public {
        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );

        // Player tries to resolve their own game
        vm.expectRevert("Not authorized");
        game.resolveGame(gameId, true);

        vm.stopPrank();
    }

    // Test resolving multiple games for a player
    function testResolveMultipleGames() public {
        vm.startPrank(player1);
        uint256 gameId1 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        uint256 gameId2 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Medium
        );
        uint256 gameId3 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Hard
        );
        vm.stopPrank();

        // Resolve games in different ways
        game.resolveGame(gameId1, true); // Win
        game.resolveGame(gameId2, false); // Loss

        // Check only gameId3 is still active
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 1);
        assertEq(activeGames[0], gameId3);
    }

    // Test contract has insufficient funds for reward
    function testInsufficientContractBalance() public {
        // Start with a large entry fee
        uint256 largeFee = 2 ether;
        vm.deal(player1, largeFee);

        vm.startPrank(player1);
        uint256 gameId = game.startGame{value: largeFee}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        // Since 2 ether * 1.5 = 3 ether, but contract only has ~5 ether (initial funding)
        // We'll withdraw most of it to simulate insufficient balance
        vm.startPrank(owner);
        game.withdrawFunds(4.9 ether);
        vm.stopPrank();

        // Now contract should have insufficient funds to pay the reward
        vm.expectRevert("Contract balance insufficient");
        game.resolveGame(gameId, true);
    }

    function testWithdrawFunds() public {
        uint256 initialContractBalance = address(game).balance; //check contract balance
        uint256 initialOwnerBalance = address(owner).balance;
        uint256 withdrawAmount = 1 ether;

        require(
            initialContractBalance >= withdrawAmount,
            "Contract has insufficient balance"
        ); // add this line
        vm.startPrank(owner);
        game.withdrawFunds(withdrawAmount);
        vm.stopPrank();

        assertEq(address(owner).balance, initialOwnerBalance + withdrawAmount);
    }

    // Test withdraw funds with insufficient balance
    function testWithdrawInsufficientFunds() public {
        uint256 contractBalance = address(game).balance;

        // Try to withdraw more than contract balance
        vm.expectRevert("Insufficient balance");
        game.withdrawFunds(contractBalance + 1);
    }

    // Test withdraw funds by non-owner
    function testWithdrawNonOwner() public {
        vm.startPrank(player1);

        vm.expectRevert("Not authorized");
        game.withdrawFunds(1 ether);

        vm.stopPrank();
    }

    // Test funding the contract
    function testFundContract() public {
        uint256 initialBalance = address(game).balance;
        uint256 fundAmount = 1 ether;

        game.fundContract{value: fundAmount}();

        assertEq(address(game).balance, initialBalance + fundAmount);
    }

    // Test fund contract by non-owner
    function testFundContractNonOwner() public {
        vm.startPrank(player1);

        vm.expectRevert("Not authorized");
        game.fundContract{value: 1 ether}();

        vm.stopPrank();
    }

    // Test getPlayerActiveGames with no games
    function testGetPlayerActiveGamesEmpty() public {
        uint256[] memory activeGames = game.getPlayerActiveGames(player1);
        assertEq(activeGames.length, 0);
    }

    // Test events are emitted correctly
    function testEvents() public {
        // Test GameStarted event
        vm.startPrank(player1);

        vm.expectEmit(true, true, true, true);
        emit GuessTheCharacter.GameStarted(
            1,
            player1,
            GuessTheCharacter.Difficulty.Easy,
            BASE_ENTRY_FEE
        );
        uint256 gameId = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );

        vm.stopPrank();

        // Test GameWon event
        uint256 expectedReward = (BASE_ENTRY_FEE * 150) / 100;
        vm.expectEmit(true, true, true, true);
        emit GuessTheCharacter.GameWon(gameId, player1, expectedReward);
        game.resolveGame(gameId, true);

        // Test GameLost event
        vm.startPrank(player1);
        uint256 gameId2 = game.startGame{value: BASE_ENTRY_FEE}(
            GuessTheCharacter.Difficulty.Easy
        );
        vm.stopPrank();

        vm.expectEmit(true, true, true, true);
        emit GuessTheCharacter.GameLost(gameId2, player1);
        game.resolveGame(gameId2, false);
    }

    receive() external payable {} // Add this to accept ETH
}
