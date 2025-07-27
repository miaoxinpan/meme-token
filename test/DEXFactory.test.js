const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DEXFactory", function () {
  let DEXFactory, dexFactory, tokenA, tokenB;

  beforeEach(async function () {
    // 部署 DEXFactory 合约
    DEXFactory = await ethers.getContractFactory("DEXFactory");
    dexFactory = await DEXFactory.deploy();
    await dexFactory.deployed();

    // 部署两个测试代币
    const Token = await ethers.getContractFactory("ERC20");
    tokenA = await Token.deploy("TokenA", "TKA");
    tokenB = await Token.deploy("TokenB", "TKB");
    await tokenA.deployed();
    await tokenB.deployed();
  });

  describe("createPair", function () {
    it("should create a new pair", async function () {
      // 调用 createPair
      const tx = await dexFactory.createPair(tokenA.address, tokenB.address);
      const receipt = await tx.wait();

      // 验证事件
      const event = receipt.events?.find((e) => e.event === "PairCreated");
      expect(event).to.not.be.undefined;
      expect(event.args.tokenA).to.equal(tokenA.address);
      expect(event.args.tokenB).to.equal(tokenB.address);

      // 验证代币对记录
      const pairAddress = await dexFactory.pairs(tokenA.address, tokenB.address);
      expect(pairAddress).to.not.equal(ethers.constants.AddressZero);
    });

    it("should fail if token addresses are identical", async function () {
      // 调用 createPair 并验证失败
      await expect(
        dexFactory.createPair(tokenA.address, tokenA.address)
      ).to.be.revertedWith("Identical addresses");
    });

    it("should fail if pair already exists", async function () {
      // 第一次调用 createPair
      await dexFactory.createPair(tokenA.address, tokenB.address);

      // 第二次调用 createPair 并验证失败
      await expect(
        dexFactory.createPair(tokenA.address, tokenB.address)
      ).to.be.revertedWith("Pair already exists");
    });
  });
});