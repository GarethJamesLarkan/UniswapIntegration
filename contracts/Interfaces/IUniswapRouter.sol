// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

interface IUniswapRouter {
    function createUniswapPool(
        address _tokenA,
        address _tokenB,
        uint24 _fee
    ) external returns (address);

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
        );

    function collectAllFees(uint256 _tokenId) external returns (uint256 amount0, uint256 amount1);
}
