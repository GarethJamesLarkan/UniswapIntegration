/* eslint-disable no-unused-expressions */
/* eslint-disable no-unused-vars */
const { expect } = require("chai");
const { ethers } = require("hardhat");

let Factory, FactoryInstance;
let ERC721A, ERC721AInstance;

let owner, minterOne, minterTwo, mintingReciever;
let ownerAddress, minterOneAddress, minterTwoAddress, mintingRecieverAddress;

describe("ERC721A Contract Tests", function () {
  beforeEach(async () => {
    [owner, minterOne, minterTwo, mintingReciever] = await ethers.getSigners();
    
    ownerAddress = await owner.getAddress();
    minterOneAddress = await minterOne.getAddress();
    minterTwoAddress = await minterTwo.getAddress();
    mintingRecieverAddress = await mintingReciever.getAddress();

    Factory = await ethers.getContractFactory("DAOFactory");
    FactoryInstance = await Factory.connect(owner).deploy();

    ERC721A = await ethers.getContractFactory("NFTERC721A");
    ERC721AInstance = await ERC721A.connect(owner).deploy(
      1000,
      50,
      ethers.utils.parseUnits("10"),
      "Test 1",
      "T1",
      "ipfs://Qadidsnfkjjadfa/",
      mintingRecieverAddress,
      FactoryInstance.address
    );
  });

  describe("Deployment", function () {
    it("Should deploy the contract", async function () {
      expect(ERC721AInstance.address).to.exist;
    }).timeout(0);

    it("Should have the correct name", async function () {
      expect(await ERC721AInstance.connect(owner).name()).to.equal("Test 1");
    });

    it("Should have the correct symbol", async function () {
      expect(await ERC721AInstance.connect(owner).symbol()).to.equal("T1");
    });

    it("Should set the correct max supply of tokens", async function () {
      expect(await ERC721AInstance.connect(owner).maxSupply()).to.equal(1000);
    });

    it("Should set the correct max per wallet", async function () {
      expect(await ERC721AInstance.connect(owner).maxPerWallet()).to.equal(50);
    });

    it("Should set the correct max supply of tokens", async function () {
      expect(await ERC721AInstance.connect(owner).mintingRecipient()).to.equal(mintingRecieverAddress);
    });

    it("Should set the correct max per wallet", async function () {
      expect(await ERC721AInstance.connect(owner).DAOFactoryAddress()).to.equal(FactoryInstance.address);
    });

  });

});