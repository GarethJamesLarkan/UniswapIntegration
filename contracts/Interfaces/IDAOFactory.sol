// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IDAOFactory {

    function addCompanyNFTsSold(uint256 _companyID, uint256 _quantity) external;

    function addTotalRevueToCompany(uint256 _companyID, uint256 _price) external;
}