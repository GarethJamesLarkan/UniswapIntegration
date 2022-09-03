// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol";
import "hardhat/console.sol";

contract NFTERC721A is ERC721A {

    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public nftPrice;
    string public baseUri;
    
    constructor(
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _nftPrice,
        string _tokenName,
        string _tokenSymbol,
        string _baseUri
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
        nftPrice = _nftPrice;
        baseUri = _baseUri;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenUri;
    }
}