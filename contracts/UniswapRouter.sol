// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.7.6;
pragma abicoder v2;

import "./Interfaces/IUniswapRouter.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/interfaces/INonfungiblePositionManager.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
import "@uniswap/v3-periphery/contracts/base/LiquidityManagement.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract UniswapRouter is IERC721Receiver {

    IUniswapV3Factory public factory = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);

    INonfungiblePositionManager public nonfungiblePositionManager =
        INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    /// @notice Represents the deposit of an NFT
    struct Deposit {
        address owner;
        uint128 liquidity;
        address token0;
        address token1;
    }

    /// @dev deposits[tokenId] => Deposit
    mapping(uint256 => Deposit) public deposits;

    // Implementing `onERC721Received` so this contract can receive custody of erc721 tokens
    function onERC721Received(
        address operator,
        address,
        uint256 _tokenId,
        bytes calldata
    ) external override returns (bytes4) {
        _createDeposit(operator, _tokenId);
        return this.onERC721Received.selector;
    }

    function _createDeposit(address owner, uint256 _tokenId) internal {
        (, , address token0, address token1, , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(
            _tokenId
        );
        // set the owner and data for position
        // operator is msg.sender
        deposits[_tokenId] = Deposit({owner: owner, liquidity: liquidity, token0: token0, token1: token1});
    }

    function mintNewPosition(
        address _tokenA,
        address _tokenB,
        uint256 _amountToken1,
        uint256 _amountToken2,
        uint24 _poolFee
    )
        external
        returns (
            uint256 _tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        // Approve the position manager
        TransferHelper.safeApprove(_tokenA, address(nonfungiblePositionManager), _amountToken1);
        TransferHelper.safeApprove(_tokenB, address(nonfungiblePositionManager), _amountToken2);

        INonfungiblePositionManager.MintParams memory params = INonfungiblePositionManager.MintParams({
            token0: _tokenA,
            token1: _tokenB,
            fee: _poolFee,
            tickLower: TickMath.MIN_TICK,
            tickUpper: TickMath.MAX_TICK,
            amount0Desired: _amountToken1,
            amount1Desired: _amountToken2,
            amount0Min: 0,
            amount1Min: 0,
            recipient: address(this),
            deadline: block.timestamp
        });

        // Note that the pool defined by DAI/USDC and fee tier 0.01% must
        // already be created and initialized in order to mint
        (_tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager.mint(params);

        // Create a deposit
        _createDeposit(msg.sender, _tokenId);

        // Remove allowance and refund in both assets.
        if (amount0 < _amountToken1) {
            TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), 0);
            uint256 refund0 = _amountToken1 - amount0;
            TransferHelper.safeTransfer(DAI, msg.sender, refund0);
        }

        if (amount1 < _amountToken2) {
            TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), 0);
            uint256 refund1 = _amountToken2 - amount1;
            TransferHelper.safeTransfer(USDC, msg.sender, refund1);
        }
    }

    function collectAllFees(uint256 _tokenId) external returns (uint256 amount0, uint256 amount1) {
        // Caller must own the ERC721 position, meaning it must be a deposit

        // set amount0Max and amount1Max to uint256.max to collect all fees
        // alternatively can set recipient to msg.sender and avoid another transaction in `sendToOwner`
        INonfungiblePositionManager.CollectParams memory params = INonfungiblePositionManager.CollectParams({
            tokenId: _tokenId,
            recipient: address(this),
            amount0Max: type(uint128).max,
            amount1Max: type(uint128).max
        });

        (amount0, amount1) = nonfungiblePositionManager.collect(params);

        // send collected feed back to owner
        _sendToOwner(_tokenId, amount0, amount1);
    }

    function increaseLiquidityCurrentRange(uint256 amountAdd0, uint256 amountAdd1, uint256 _tokenId)
        external
        returns (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        )
    {
        //Changhe to our tokens
        TransferHelper.safeTransferFrom(DAI, msg.sender, address(this), amountAdd0);
        TransferHelper.safeTransferFrom(USDC, msg.sender, address(this), amountAdd1);

        //Change to our tokens
        TransferHelper.safeApprove(DAI, address(nonfungiblePositionManager), amountAdd0);
        TransferHelper.safeApprove(USDC, address(nonfungiblePositionManager), amountAdd1);

        INonfungiblePositionManager.IncreaseLiquidityParams memory params = INonfungiblePositionManager
            .IncreaseLiquidityParams({
                tokenId: _tokenId,
                amount0Desired: amountAdd0,
                amount1Desired: amountAdd1,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (liquidity, amount0, amount1) = nonfungiblePositionManager.increaseLiquidity(params);
    }

    function getLiquidity(uint256 _tokenId) external view returns (uint128) {
        (, , , , , , , uint128 liquidity, , , , ) = nonfungiblePositionManager.positions(_tokenId);
        return liquidity;
    }

    function decreaseLiquidity(uint128 liquidity, uint256 _tokenId) external returns (uint256 amount0, uint256 amount1) {
        INonfungiblePositionManager.DecreaseLiquidityParams memory params = INonfungiblePositionManager
            .DecreaseLiquidityParams({
                tokenId: _tokenId,
                liquidity: liquidity,
                amount0Min: 0,
                amount1Min: 0,
                deadline: block.timestamp
            });

        (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(params);

    }

    function createUniswapPool(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) public returns (address) {
        console.log("Check");
        address poolAddress = factory.createPool(_tokenA, _tokenB, _fee);
                console.log("Check");

        return poolAddress;
    }

    /// @notice Transfers funds to owner of NFT
    /// @param tokenId The id of the erc721
    /// @param amount0 The amount of token0
    /// @param amount1 The amount of token1
    function _sendToOwner(
        uint256 tokenId,
        uint256 amount0,
        uint256 amount1
    ) internal {
        // get owner of contract
        address owner = deposits[tokenId].owner;

        address token0 = deposits[tokenId].token0;
        address token1 = deposits[tokenId].token1;
        // send collected fees to owner
        TransferHelper.safeTransfer(token0, owner, amount0);
        TransferHelper.safeTransfer(token1, owner, amount1);
    }
}
