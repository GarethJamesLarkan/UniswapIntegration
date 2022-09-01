// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BridgeFactory {

    struct Company {
        uint256 ID;
        string name;
        address wallet;
        address[] contractInstances;
    }

    uint256 public companyNumber = 1;

    mapping(uint256 => Company) public companies;

    event CompanyCreated(uint256 companyID, string name, address wallet);

    function createCompany(Company memory company) external {
        require(company.wallet != address(0), "Cannot be zero-address");
        company.ID = companyNumber;
        companies[companyNumber] = company;
        companyNumber++;

        emit CompanyCreated(company.ID, company.name, company.wallet);
    }


    
}