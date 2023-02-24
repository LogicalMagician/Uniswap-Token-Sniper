// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract TokenSniper {
    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Mainnet address. For other testnets, use the respective address.
    IUniswapV2Router02 private uniswapRouter;

    address public tokenAddress;
    uint256 public deadline;
    uint256 public minTokensToBuy;
    uint256 public blocksToWait;

    uint256 public liquidityAddedBlock;
    bool public boughtTokens;

    constructor(address _tokenAddress, uint256 _deadline, uint256 _minTokensToBuy, uint256 _blocksToWait) {
        tokenAddress = _tokenAddress;
        deadline = _deadline;
        minTokensToBuy = _minTokensToBuy;
        blocksToWait = _blocksToWait;
        uniswapRouter = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
    }

    function buyToken() public payable {
        require(msg.value > 0, "Value must be greater than 0");
        require(boughtTokens == false, "Tokens already bought");
        require(block.number >= liquidityAddedBlock + blocksToWait, "Not enough blocks mined since liquidity added");
        require(IERC20(tokenAddress).balanceOf(address(this)) >= minTokensToBuy, "Token balance not sufficient");
        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = tokenAddress;
        uint[] memory amounts = uniswapRouter.swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline);
        IERC20(tokenAddress).transfer(msg.sender, amounts[1]);
        boughtTokens = true;
    }

    function approveToken() public {
        IERC20(tokenAddress).approve(address(uniswapRouter), type(uint256).max);
    }

    function withdraw() public {
        require(msg.sender == address(this), "Only contract address can call this function");
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken() public {
        require(msg.sender == address(this), "Only contract address can call this function");
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }

    function receiveTokens(uint256 amount) public {
        require(msg.sender == tokenAddress, "Only token contract can call this function");
        IERC20(tokenAddress).transfer(address(this), amount);
        liquidityAddedBlock = block.number;
    }

    function() external payable {}
}
