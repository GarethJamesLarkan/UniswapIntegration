// Current Version of solidity
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Interfaces/IMockToken.sol";
import "./Interfaces/IUniswapRouter.sol";
import "hardhat/console.sol";

contract GameContract {
    address public tokenAddress;
    address public uniswapRouterAddress;

    uint256 public gameInstance = 1;

    mapping(uint256 => Game) public games;

    struct Game {
        uint256 answer;
        uint256 numberOfBets;
        uint256 player1Bet;
        uint256 player2Bet;
        uint256 player1Guess;
        uint256 player2Guess;
        uint256 poolAmount;
        uint24 poolFee;
        address token1;
        address token2;
        address player1;
        address player2;
        address winner;
        address creator;
    }

    IUniswapRouter router;

    constructor(address _routerAddress, address _ERC20Address) {
        tokenAddress = _ERC20Address;
        uniswapRouterAddress = _routerAddress;

        router = IUniswapRouter(_routerAddress);
    }

    //User can create a game, specifying which secondary token will be used with the MockToken
    //A uniswap pool will be created the two tokens
    //On placements of bets, the liquidity will be added to the pool
    //The winner of the game will then recieve the 50% of the fees of that pool and the created will recieve the other 50%
    //The creater sets a number between 0 and 1000, each player guesses the number and whoever is closer wins the game
    function createGame(
        address _token2,
        uint256 _answer,
        uint256 _betAmount,
        uint24 _poolFee
    ) public {
        require(_answer > 0 && _answer <= 1000, "Invalid answer");
        require(_token2 != address(0), "Cannot be zero-address");

        console.log("Check");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _betAmount);
                console.log("Check");

        address poolAddress = router.createUniswapPool(tokenAddress, _token2, _poolFee);
        console.log("Check");

        games[gameInstance] = Game({
            answer: _answer,
            numberOfBets: 0,
            player1Bet: 0,
            player2Bet: 0,
            token1: tokenAddress,
            token2: _token2,
            player1: address(0),
            player2: address(0),
            player1Guess: 0,
            player2Guess: 0,
            winner: address(0),
            poolAmount: _betAmount,
            poolFee: _poolFee,
            creator: msg.sender
        });
        console.log("Check");

        gameInstance++;
    }

    //Users can select a game and enter a bet
    //If they are player 1, it will record their bet and transfer funds! NOTE player has to approve their bet amount
    //If they are player 2, it will record their bet and transfer funds! As well as calculate winner and mint the uniswap pool
    function playGame(
        uint256 _gameId,
        uint256 _guess,
        uint256 _betAmount
    ) public {
        require(games[_gameId].numberOfBets <= 2, "Game over");
        require(_gameId > 0 && _gameId < gameInstance, "Invalid game");
        require(_betAmount == games[_gameId].poolAmount / 2, "Incorrect bet amount");
        require(msg.sender != games[_gameId].creator, "Creator cannot play");

        if (games[_gameId].numberOfBets == 0) {
            require(
                IERC20(games[_gameId].token2).transferFrom(msg.sender, address(this), _betAmount),
                "Payment Failed"
            );
            games[_gameId].player1 = msg.sender;
            games[_gameId].player1Bet = _betAmount;
            games[_gameId].numberOfBets++;
        } else {
            require(msg.sender != games[_gameId].player1, "Already player 1");
            require(
                IERC20(games[_gameId].token2).transferFrom(msg.sender, address(this), _betAmount),
                "Payment Failed"
            );
            games[_gameId].player2 = msg.sender;
            games[_gameId].player2Bet = _betAmount;
            games[_gameId].numberOfBets++;

            address _winner = calculateWinner(_gameId);

            games[_gameId].winner = _winner;

            router.mintNewPosition(
                games[_gameId].token1,
                games[_gameId].token2,
                games[_gameId].poolAmount,
                games[_gameId].poolAmount,
                games[_gameId].poolFee
            );
        }
    }

    //Winner is the player with the smallest difference
    //If tied, winner is first better
    function calculateWinner(uint256 _gameId) internal returns (address) {
        uint256 player1Guess = games[_gameId].player1Guess;
        uint256 player2Guess = games[_gameId].player2Guess;
        address player1 = games[_gameId].player1;
        address player2 = games[_gameId].player2;

        uint256 player1Diff;
        uint256 player2Diff;

        if (games[_gameId].answer > player1Guess) {
            player1Diff = (games[_gameId].answer - player1Guess);
        } else {
            player1Diff = (player1Guess - games[_gameId].answer);
        }

        if (games[_gameId].answer > player2Guess) {
            player2Diff = (games[_gameId].answer - player2Guess);
        } else {
            player2Diff = (player2Guess - games[_gameId].answer);
        }

        if (player1Diff > player2Diff) {
            return player2;
        } else {
            return player1;
        }
    }

    //Pool creator will constantly just collect the fees of the pool and the funds will be distributed
    function collectPoolFees(uint256 _gameId) public {
        require(_gameId > 0 && _gameId <= gameInstance, "Invalid pool");
        require(msg.sender == games[_gameId].creator, "Incorrect caller");

        (uint256 amount0, uint256 amount1) = router.collectAllFees(_gameId);

        IERC20(games[_gameId].token1).transfer(games[_gameId].creator, amount0 / 2);
        IERC20(games[_gameId].token1).transfer(games[_gameId].winner, amount0 / 2);
        IERC20(games[_gameId].token2).transfer(games[_gameId].creator, amount1 / 2);
        IERC20(games[_gameId].token2).transfer(games[_gameId].winner, amount1 / 2);
    }
}
