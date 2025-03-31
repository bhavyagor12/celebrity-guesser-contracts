// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GuessTheCharacter {
    address public owner;
    uint256 public baseEntryFee = 0.001 ether; // ~ $2 equivalent in ETH

    enum Difficulty {
        Easy,
        Medium,
        Hard
    }
    struct Game {
        address player;
        Difficulty difficulty;
        uint256 entryFee;
        bool isActive;
    }

    mapping(address => Game) public activeGames;
    mapping(Difficulty => uint256) public rewardMultipliers;

    event GameStarted(
        address indexed player,
        Difficulty difficulty,
        uint256 entryFee
    );
    event GameWon(address indexed player, uint256 reward);
    event GameLost(address indexed player);

    constructor() {
        owner = msg.sender;
        rewardMultipliers[Difficulty.Easy] = 150; // 1.5x
        rewardMultipliers[Difficulty.Medium] = 125; // 1.25x
        rewardMultipliers[Difficulty.Hard] = 111; // 1.11x
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyActiveGame() {
        require(activeGames[msg.sender].isActive, "No active game found");
        _;
    }

    function startGame(Difficulty _difficulty) external payable {
        require(msg.value >= baseEntryFee, "Insufficient entry fee");
        require(!activeGames[msg.sender].isActive, "Already in an active game");

        activeGames[msg.sender] = Game({
            player: msg.sender,
            difficulty: _difficulty,
            entryFee: msg.value,
            isActive: true
        });

        emit GameStarted(msg.sender, _difficulty, msg.value);
    }

    function resolveGame(bool won) external onlyOwner onlyActiveGame {
        Game storage game = activeGames[msg.sender];

        if (won) {
            uint256 reward = (game.entryFee *
                rewardMultipliers[game.difficulty]) / 100;
            require(
                address(this).balance >= reward,
                "Contract balance insufficient"
            );

            payable(msg.sender).transfer(reward);
            emit GameWon(msg.sender, reward);
        } else {
            emit GameLost(msg.sender);
        }

        delete activeGames[msg.sender];
    }

    function fundContract() external payable onlyOwner {}

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient funds");
        payable(owner).transfer(amount);
    }
}
