const { expect } = require("chai")
const { ethers } = require("hardhat")

const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F"
const USDC = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48"
const DAI_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"
const USDC_WHALE = "0x2FAF487A4414Fe77e2327F0bf4AE2a264a776AD2"

describe("UniswapRouter", () => {
  let UniswapRouter, accounts, dai, usdc, UniswapRouterInstance;

  before(async () => {
    accounts = await ethers.getSigners(1)

    UniswapRouter = await ethers.getContractFactory(
      "UniswapRouter"
    )
    UniswapRouterInstance = await UniswapRouter.deploy()
    await UniswapRouterInstance.deployed()

    dai = await ethers.getContractAt("IERC20", DAI)
    usdc = await ethers.getContractAt("IERC20", USDC)

    // Unlock DAI and USDC whales
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [DAI_WHALE],
    })
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [USDC_WHALE],
    })

    const daiWhale = await ethers.getSigner(DAI_WHALE)
    const usdcWhale = await ethers.getSigner(USDC_WHALE)

    // Send DAI and USDC to accounts[0]
    const daiAmount = 1000n * 10n ** 18n
    const usdcAmount = 1000n * 10n ** 6n

    expect(await dai.balanceOf(daiWhale.address)).to.gte(daiAmount)
    expect(await usdc.balanceOf(usdcWhale.address)).to.gte(usdcAmount)

    await dai.connect(daiWhale).transfer(accounts[0].address, daiAmount)
    await usdc.connect(usdcWhale).transfer(accounts[0].address, usdcAmount)
  })

  it("mintNewPosition", async () => {
    const daiAmount = 100n * 10n ** 18n
    const usdcAmount = 100n * 10n ** 6n

    await dai
      .connect(accounts[0])
      .transfer(UniswapRouterInstance.address, daiAmount)
    await usdc
      .connect(accounts[0])
      .transfer(UniswapRouterInstance.address, usdcAmount)

    await UniswapRouterInstance.mintNewPosition()

    console.log(
      "DAI balance after add liquidity",
      await dai.balanceOf(accounts[0].address)
    )
    console.log(
      "USDC balance after add liquidity",
      await usdc.balanceOf(accounts[0].address)
    )
  })

  it.skip("increaseLiquidityCurrentRange", async () => {
    const daiAmount = 20n * 10n ** 18n
    const usdcAmount = 20n * 10n ** 6n

    await dai.connect(accounts[0]).approve(UniswapRouterInstance.address, daiAmount)
    await usdc
      .connect(accounts[0])
      .approve(UniswapRouterInstance.address, usdcAmount)

    await UniswapRouterInstance.increaseLiquidityCurrentRange(daiAmount, usdcAmount)
  })

  it("decreaseLiquidity", async () => {
    const tokenId = await UniswapRouterInstance.tokenId()
    const liquidity = await UniswapRouterInstance.getLiquidity(tokenId)

    await UniswapRouterInstance.decreaseLiquidity(liquidity)

    console.log("--- decrease liquidity ---")
    console.log(`liquidity ${liquidity}`)
    console.log(`dai ${await dai.balanceOf(UniswapRouterInstance.address)}`)
    console.log(`usdc ${await usdc.balanceOf(UniswapRouterInstance.address)}`)
  })

  it("collectAllFees", async () => {
    await UniswapRouterInstance.collectAllFees()

    console.log("--- collect fees ---")
    console.log(`dai ${await dai.balanceOf(UniswapRouterInstance.address)}`)
    console.log(`usdc ${await usdc.balanceOf(UniswapRouterInstance.address)}`)
  })
})