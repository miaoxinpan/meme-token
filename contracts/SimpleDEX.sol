// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract SimpleDEX is OwnableUpgradeable{
    // 代币对
    address public tokenA;
    address public tokenB;

    // 流动性池余额
    uint256 public reserveA;
    uint256 public reserveB;

    // 流动性提供者份额
    mapping(address => uint256) public liquidity;
    uint256 public totalLiquidity;

    // 手续费比例（0.3%，类似于 Uniswap）
    uint256 public constant FEE = 30; // 0.3%

    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut);
    event AddLiquidity(address indexed provider, uint256 amountA, uint256 amountB);
    event RemoveLiquidity(address indexed provider, uint256 amountA, uint256 amountB);


    //初始化化合约, 可以在创建合约时设置两个代币, 或者后续通过addLiquidity重新设置, 
    //因为合约创建以后，不能重置tokenA 和 tokenB 的地址。 
    function initialize(address _tokenA, address _tokenB) external initializer {
        require(tokenA == address(0) && tokenB == address(0), "Already initialized");
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // 添加流动性
    function addLiquidity(uint256 amountA, uint256 amountB) external {
        require(amountA > 0 && amountB > 0, "Amounts must be greater than 0");

        // 首次添加流动性时，直接设置比例
        if (totalLiquidity == 0) {
            liquidity[msg.sender] = amountA;
            totalLiquidity = amountA;
        } else {
            // 后续添加流动性时，按比例计算份额
            uint256 liquidityAmount = (amountA * totalLiquidity) / reserveA;
            liquidity[msg.sender] += liquidityAmount;
            totalLiquidity += liquidityAmount;
        }

        // 更新储备
        reserveA += amountA;
        reserveB += amountB;

        // 转移代币
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        emit AddLiquidity(msg.sender, amountA, amountB);
    }

    // 移除流动性
    function removeLiquidity(uint256 liquidityAmount) external {
        require(liquidity[msg.sender] >= liquidityAmount, "Insufficient liquidity");

        // 计算应返还的代币数量
        uint256 amountA = (liquidityAmount * reserveA) / totalLiquidity;
        uint256 amountB = (liquidityAmount * reserveB) / totalLiquidity;

        // 更新储备和份额
        reserveA -= amountA;
        reserveB -= amountB;
        liquidity[msg.sender] -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        // 返还代币
        IERC20(tokenA).transfer(msg.sender, amountA);
        IERC20(tokenB).transfer(msg.sender, amountB);

        emit RemoveLiquidity(msg.sender, amountA, amountB);
    }

    // 代币交换
    function swap(address tokenIn, uint256 amountIn) external returns (uint256 amountOut) {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");
        require(amountIn > 0, "Amount must be greater than 0");

        // 计算手续费
        uint256 fee = (amountIn * FEE) / 10000;
        uint256 amountInAfterFee = amountIn - fee;

        // 计算输出数量（使用恒定乘积公式）
        if (tokenIn == tokenA) {
            amountOut = (reserveB * amountInAfterFee) / (reserveA + amountInAfterFee);
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            amountOut = (reserveA * amountInAfterFee) / (reserveB + amountInAfterFee);
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        // 转移代币
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn == tokenA ? tokenB : tokenA).transfer(msg.sender, amountOut);

        emit Swap(msg.sender, amountIn, amountOut);
        return amountOut;
    }

    // 获取代币对价格
    function getPrice(address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        require(tokenIn == tokenA || tokenIn == tokenB, "Invalid token");

        uint256 amountInAfterFee = amountIn - (amountIn * FEE) / 10000;

        if (tokenIn == tokenA) {
            amountOut = (reserveB * amountInAfterFee) / (reserveA + amountInAfterFee);
        } else {
            amountOut = (reserveA * amountInAfterFee) / (reserveB + amountInAfterFee);
        }
    }
    
}