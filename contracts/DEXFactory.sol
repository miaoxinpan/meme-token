// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleDEX.sol";

contract DEXFactory {
    // 存储所有已创建的代币对
    mapping(address => mapping(address => address)) public pairs;
    // 所有代币对列表
    address[] public allPairs;

    event PairCreated(address indexed tokenA, address indexed tokenB, address pair, uint256 length);

    // 创建新的代币对
    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "Identical addresses");
        // 确保代币对不存在
        require(pairs[tokenA][tokenB] == address(0), "Pair already exists");

        // 创建新的 SimpleDEX 合约
        bytes memory bytecode = type(SimpleDEX).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenA, tokenB));
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // 初始化 SimpleDEX 合约
        SimpleDEX(pair).initialize(tokenA, tokenB);

        // 记录代币对
        pairs[tokenA][tokenB] = pair;
        pairs[tokenB][tokenA] = pair;
        allPairs.push(pair);

        emit PairCreated(tokenA, tokenB, pair, allPairs.length);
        return pair;
    }

    // 获取代币对数量
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }
}