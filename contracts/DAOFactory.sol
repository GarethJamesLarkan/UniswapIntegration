// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./NFTERC721A.sol";

contract DAOFactory {

    struct Company {
        uint256 ID;
        uint256 numberNFTsSold;
        uint256 totalValueSold;
        string name;
        address wallet;
        address[] admins;
        address[] contractInstances;
    }

    uint256 public companyNumber = 1;

    mapping(uint256 => Company) public companies;
    mapping(uint256 => address) companyToNFTAddress;

    event CompanyCreated(uint256 companyID, string name, address wallet);
    event UpdatedCompanyWallet(uint256 companyID, address oldAddress, address newAddress);
    event AddedCompanyAdmin(uint256 companyID, address newAdmin);

    //---------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------- CREATE FUNCTIONS ----------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function createCompany(Company memory company) external isZeroAddress(company.wallet) {
        
        companies[companyNumber] = company;
        companies[companyNumber].admins.push(msg.sender);
        companyNumber++;

        emit CompanyCreated(company.ID, company.name, company.wallet);
    }

    function createERC721AInstance(
        uint256 _companyID,
        uint256 _maxSupply, 
        uint256 _maxPerWallet, 
        uint256 _nftPrice, 
        string memory _tokenName, 
        string memory _tokenSymbol, 
        string memory _baseUri,
        address _mintingRecipient, 
        address _daoFactoryAddress) external isZeroAddress(_mintingRecipient) isZeroAddress(_daoFactoryAddress) {

            require(isCompanyAdmin(_companyID, msg.sender), "Not company admin");
            require(_maxPerWallet < _maxSupply, "Max per wallet to high");

            NFTERC721A nftInstance = new NFTERC721A(
                _maxSupply, 
                _maxPerWallet, 
                _nftPrice,
                _tokenName, 
                _tokenSymbol, 
                _baseUri,
                _mintingRecipient, 
                _daoFactoryAddress
            );

            address nftInstanceAddress = address(nftInstance);

            companies[_companyID].contractInstances.push(nftInstanceAddress);
            companyToNFTAddress[_companyID] = nftInstanceAddress;         

    }

    //---------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------- SETTER FUNCTIONS ----------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function setCompanyWallet(uint256 _companyID, address _newWalletAddress) external isCompany(_companyID) isZeroAddress(_newWalletAddress) {
        require(isCompanyAdmin(_companyID, msg.sender), "Not company admin");

        address oldWallet = companies[_companyID].wallet;
        companies[_companyID].wallet = _newWalletAddress;

        emit UpdatedCompanyWallet(_companyID, oldWallet, _newWalletAddress);

    }

    //---------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------- GETTER FUNCTIONS ----------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function isCompanyAdmin(uint256 _companyID, address _admin) internal view returns (bool){
        for(uint256 x = 0; x < (companies[_companyID].admins).length; x++){
            if(companies[_companyID].admins[x] == _admin){
                return true;
            }
        }

        return false;
    }

    //---------------------------------------------------------------------------------------------------------------------------------
    //------------------------------------------------- STATE MODIFYING FUNCTIONS -----------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function addAdmin(uint256 _companyID, address _newAdmin) external isCompany(_companyID) isZeroAddress(_newAdmin) {
        companies[_companyID].admins.push(_newAdmin);

        emit AddedCompanyAdmin(_companyID, _newAdmin);

    }

    function addCompanyNFTsSold(uint256 _companyID, uint256 _quantity) external {
        companies[_companyID].numberNFTsSold += _quantity;
    }

    function addTotalRevueToCompany(uint256 _companyID, uint256 _price) external {
        companies[_companyID].totalValueSold += _price;
    }

    //Need to add remove admin function
    
    //---------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------- GETTERS  -------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function getCompanyNFTContract(uint256 _companyID) external view returns(address) {
        require(_companyID <= companyNumber, "Non-existant company ID");

        return companyToNFTAddress[_companyID];
    }

    //---------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------- MODIFIERS ------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    modifier isCompany(uint256 _companyID) {
        require(_companyID <= companyNumber, "Non-existant company ID");
        _;
    }

    modifier isZeroAddress(address _address) {
        require(_address != address(0), "Cannot be zero-address");
        _;
    }

    
}