// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

//导入erc20接口
//导入uups代理
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract MemeToken is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 1e18;    // 1亿枚
    uint256 public constant INFLATION_RATE = 5; // 5%通胀 这个通胀按道理来说要根据流动性来修改浮动的，但是我们这个模型比较简单就不动了
    uint256 public constant DIVIDEND_RATE = 2;  // 2%分红 
    uint256 public constant BURN_RATE = 3;      // 3%销毁
    uint256 public constant gapBlockNumber = 8640;    // 多少个区块分一次红
    uint256 public constant BLOCKS_PER_YEAR = 3_153_600; // 10秒/区块
    uint256 public deployBlockNumber;//部署时的区块号
    uint256 public lastDividendBlock; // 上次分红的区块号
    uint256 public lastDividendRemainder; // 上次分红剩余的数量 没分完的
    uint256 public totalDividends; // 总分红数量
    uint256 public totalBurned; // 总销毁数量
    address public dividendPool;// 分红池地址
    mapping(address => bool) public blacklist; // 黑名单



    // 映射地址到余额
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // 初始化函数
    function initialize(address _dividendPool) public initializer {
        __ERC20_init("MemeToken", "MEME");
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        _mint(msg.sender, INITIAL_SUPPLY);
        dividendPool = _dividendPool;
    }

    // 实现代理合约升级的接口
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // 黑名单管理
    function setBlacklist(address user, bool status) external onlyOwner {
        blacklist[user] = status;
    }

    /**
     * 代币税功能：实现交易税机制，对每笔代币交易征收一定比例的税费，并将税费分配给特定的地址或用于特定的用途。
     * 重写交易的transfer函数
     */
    // 转账重写，集成交易税
    function _transfer(address from, address to, uint256 amount) internal override {
        require(!blacklist[from] && !blacklist[to], "Blacklisted");
        uint256 fee = (amount * INFLATION_RATE) / 100;//手续费
        uint256 burnAmount = (amount * BURN_RATE) / 100;//销毁费率
        uint256 dividendAmount = (amount * DIVIDEND_RATE) / 100;//分红费率
        uint256 sendAmount = amount - fee;//发送的金额

        super._transfer(from, address(0), burnAmount); // 销毁
        super._transfer(from, dividendPool, dividendAmount); // 分红池
        super._transfer(from, to, sendAmount); // 实际到账
    }

}