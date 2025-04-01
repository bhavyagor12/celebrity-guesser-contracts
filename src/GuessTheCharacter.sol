// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract GuessTheCharacter {
    address public owner;
    uint256 public baseEntryFee = 0.001 ether; // ~ $2 equivalent in ETH
    uint256 private nextGameId = 1;

    enum Difficulty {
        Easy,
        Medium,
        Hard
    }

    struct Game {
        uint256 gameId;
        address player;
        Difficulty difficulty;
        uint256 entryFee;
        bool isActive;
    }

    mapping(uint256 => Game) public games;
    mapping(address => uint256[]) public playerGames;
    mapping(Difficulty => uint256) public rewardMultipliers;

    event GameStarted(
        uint256 indexed gameId,
        address indexed player,
        Difficulty difficulty,
        uint256 entryFee
    );
    event GameWon(
        uint256 indexed gameId,
        address indexed player,
        uint256 reward
    );
    event GameLost(uint256 indexed gameId, address indexed player);

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

    modifier gameExists(uint256 gameId) {
        require(games[gameId].gameId == gameId, "Game does not exist");
        _;
    }

    modifier onlyActiveGame(uint256 gameId) {
        require(games[gameId].isActive, "Game is not active");
        _;
    }

    function startGame(
        Difficulty _difficulty
    ) external payable returns (uint256) {
        require(msg.value >= baseEntryFee, "Insufficient entry fee");

        uint256 gameId = nextGameId;
        nextGameId++;

        games[gameId] = Game({
            gameId: gameId,
            player: msg.sender,
            difficulty: _difficulty,
            entryFee: msg.value,
            isActive: true
        });

        playerGames[msg.sender].push(gameId);

        emit GameStarted(gameId, msg.sender, _difficulty, msg.value);

        return gameId;
    }

    function resolveGame(
        uint256 gameId,
        bool won
    ) external onlyOwner gameExists(gameId) onlyActiveGame(gameId) {
        Game storage game = games[gameId];

        if (won) {
            uint256 reward = (game.entryFee *
                rewardMultipliers[game.difficulty]) / 100;
            require(
                address(this).balance >= reward,
                "Contract balance insufficient"
            );
            (bool success, ) = payable(game.player).call{value: reward}("");
            require(success, "Transfer failed");
            emit GameWon(gameId, game.player, reward);
        } else {
            emit GameLost(gameId, game.player);
        }

        game.isActive = false;
    }

    function getPlayerActiveGames(
        address player
    ) external view returns (uint256[] memory) {
        uint256[] memory activeGameIds = new uint256[](
            playerGames[player].length
        );
        uint256 count = 0;

        for (uint256 i = 0; i < playerGames[player].length; i++) {
            uint256 gameId = playerGames[player][i];
            if (games[gameId].isActive) {
                activeGameIds[count] = gameId;
                count++;
            }
        }

        // Resize array to actual active games count
        uint256[] memory result = new uint256[](count);
        for (uint256 i = 0; i < count; i++) {
            result[i] = activeGameIds[i];
        }

        return result;
    }

    function fundContract() external payable onlyOwner {}

    function withdrawFunds(uint256 amount) external onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}

    fallback() external payable {}
}
