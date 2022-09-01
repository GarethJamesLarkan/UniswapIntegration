// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract BridgeFactory {

    struct Company {
        uint256 ID;
        address name;
        address wallet;
        address[] contractInstances;
    }

    uint256 public companyNumber = 1;

    mapping(uint256 => Company) public companies;

    function createCompany(Company memory company) external {
        require(company.wallet != address(0), "Cannot be zero-address");
        company.ID = companyNumber;
        companies[companyNumber] = company;
    }
    
}