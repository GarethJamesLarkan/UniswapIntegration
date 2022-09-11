// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "erc721a/contracts/ERC721A.sol"; 
import "./Interfaces/IDAOFactory.sol";

//import "hardhat/console.sol";

contract NFTERC721A is ERC721A {

    uint256 public maxSupply;
    uint256 public maxPerWallet;
    uint256 public nftPrice;
    uint256 public numberOfNFTHolders;
    string public baseUri;

    address public mintingRecipient;
    address public immutable DAOFactoryAddress;

    address[] public nftHolders;


    event UpdatedTokenURI(string oldBaseUri, string newBaseUri);
    
    mapping(address => uint256) public numberOfMintedNFTSPerUser;


    constructor(
        uint256 _maxSupply,
        uint256 _maxPerWallet,
        uint256 _nftPrice,
        string memory _tokenName,
        string memory _tokenSymbol,
        string memory _baseUri,
        address _mintingRecipient,
        address _daoFactoryAddress
    ) ERC721A(_tokenName, _tokenSymbol) {
        maxSupply = _maxSupply;
        maxPerWallet = _maxPerWallet;
        nftPrice = _nftPrice;
        baseUri = _baseUri;
        mintingRecipient = _mintingRecipient;
        DAOFactoryAddress = _daoFactoryAddress;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseUri;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenID
    ) public override(ERC721A) {
        super.transferFrom(_from, _to, _tokenID);
    }

    function setTokenUri(string memory _baseTokenUri) external {
        string memory oldURI = baseUri;
        baseUri = _baseTokenUri;
        emit UpdatedTokenURI(oldURI, _baseTokenUri);
    }

    function _mint(uint256 _quantity, uint256 _price, uint256 _companyID) internal {

        IDAOFactory factory = IDAOFactory(DAOFactoryAddress);
                
        require((totalSupply() + _quantity) <= maxSupply, "Mint above max supply");
        require((numberOfMintedNFTSPerUser[msg.sender] + _quantity) <= maxPerWallet, "Above max per wallet");

        uint256 amountPayable = nftPrice * _quantity;
        
        require(_price == amountPayable, "Incorrect payment amount");

        numberOfMintedNFTSPerUser[msg.sender] = numberOfMintedNFTSPerUser[msg.sender] + _quantity;
        nftHolders.push(msg.sender);
        numberOfNFTHolders++;

        factory.addCompanyNFTsSold(_companyID, _quantity);
        factory.addTotalRevueToCompany(_companyID, _price);

        (bool sent, ) = mintingRecipient.call{value: nftPrice}("");
        require(sent, "Failed to send Ether");

        _safeMint(msg.sender, _quantity);

    }

}