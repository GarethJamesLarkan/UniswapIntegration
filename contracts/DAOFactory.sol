// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BridgeFactory {

    struct Company {
        uint256 ID;
        string name;
        address wallet;
        address[] admins;
        address[] contractInstances;
    }

    uint256 public companyNumber = 1;

    mapping(uint256 => Company) public companies;

    event CompanyCreated(uint256 companyID, string name, address wallet);
    event UpdatedCompanyWallet(uint256 companyID, address oldAddress, address newAddress);
    event AddedCompanyAdmin(uint256 companyID, address newAdmin);

    //---------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------- CREATE FUNCTIONS ----------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function createCompany(Company memory company) external {
        require(company.wallet != address(0), "Cannot be zero-address");
        
        company.ID = companyNumber;
        companies[companyNumber] = company;
        companies[companyNumber].admins.push(msg.sender);
        companyNumber++;

        emit CompanyCreated(company.ID, company.name, company.wallet);
    }

    //---------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------- SETTER FUNCTIONS ----------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    function setCompanyWallet(uint256 _companyID, address _newWalletAddress) external isCompany(_companyID) {
        require(_newWalletAddress != address(0), "Cannot be zero address");
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

    function addAdmin(uint256 _companyID, address _newAdmin) external isCompany(_companyID) {
        require(_newAdmin != address(0), "Cannot add address zero");

        companies[_companyID].admins.push(_newAdmin);

        emit AddedCompanyAdmin(_companyID, _newAdmin);

    }

    //Need to add remove admin function
    
    //---------------------------------------------------------------------------------------------------------------------------------
    //---------------------------------------------------------- MODIFIERS ------------------------------------------------------------
    //---------------------------------------------------------------------------------------------------------------------------------

    modifier isCompany(uint256 _companyID){
        require(_companyID <= companyNumber, "Non-existant company ID");
        _;
    }

    
}