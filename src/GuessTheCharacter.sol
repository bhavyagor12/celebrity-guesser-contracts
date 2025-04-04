// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CategoryGuessedNFT} from "./CategoryGuessedNFT.sol";

contract GuessTheCharacter {
    address public owner;
    uint256 public baseEntryFee = 0.001 ether;
    CategoryGuessedNFT public nftContract;

    struct Game {
        address player;
        uint256 entryFee;
        bool isActive;
    }

    mapping(address => Game) public games;

    event GameStarted(address indexed player, uint256 entryFee);
    event GameWon(address indexed player, uint256 reward, string category);
    event GameLost(address indexed player);

    constructor(address payable _nftContract) {
        owner = msg.sender;
        nftContract = CategoryGuessedNFT(_nftContract);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyActiveGame(address player) {
        require(games[player].isActive, "No active game");
        _;
    }

    function startGame() external payable {
        require(msg.value >= baseEntryFee, "Insufficient entry fee");

        games[msg.sender] = Game({
            player: msg.sender,
            entryFee: msg.value,
            isActive: true
        });

        emit GameStarted(msg.sender, msg.value);
    }

    function resolveGame(
        address player,
        bool won,
        string memory category,
        string memory svg
    ) external onlyOwner onlyActiveGame(player) {
        Game storage game = games[player];

        if (won) {
            uint256 reward = (game.entryFee * 125) / 100; // 1.25x
            require(
                address(this).balance >= reward,
                "Contract balance insufficient"
            );

            (bool success, ) = payable(player).call{value: reward}("");
            require(success, "Transfer failed");

            // Mint NFT to winner
            nftContract.mintCategoryGuessedNFT(player, category, svg);

            emit GameWon(player, reward, category);
        } else {
            emit GameLost(player);
        }

        game.isActive = false;
    }

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
