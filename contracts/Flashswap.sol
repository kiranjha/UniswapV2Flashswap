//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 <=0.6.12;

import './interfaces/IERC20.sol';
import './interfaces/Uniswap.sol';
import "hardhat/console.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external; 
}
contract Flashswap is IUniswapV2Callee {
    address private TokenA;
    address private TokenB;
    address private TokenC;
    address private UniswapV2Factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address private UniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    uint256 private beforeFlashBalA;
    uint256 private beforeFlashBalB;
    uint256 private beforeFlashBalC;
    // uint256 private afterFlashBal;

    constructor (address _tokenA, address _tokenB, address _tokenC) public {
        TokenA = _tokenA;
        TokenB = _tokenB;
        TokenC = _tokenC;
    }

    // we'll call this function to call to call FLASHLOAN on uniswap
    function testFlashSwap(address _tokenBorrow, uint256 _amount) external {
        console.log("1.1");
        console.log("1.2");
        IERC20(TokenA).approve(UniswapV2Router, 1000000);
        IERC20(TokenB).approve(UniswapV2Router, 1000000);
        IERC20(TokenC).approve(UniswapV2Router, 1000000);
            console.log("1.5");
        // check the pair contract for token borrow and TokenA exists
        address pair = IUniswapV2Factory(UniswapV2Factory).getPair(
            _tokenBorrow,
            TokenB
        );
        console.log("Pool A/B Pair address :- ",pair);
        {
        require(pair != address(0), "!pair");
        // right now we dont know tokenborrow belongs to which token
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        console.log("token0 :- ",token0);
        console.log("token1 :- ",token1);
        console.log("1.6");
        // as a result, either amount0out will be equal to 0 or amount1out will be
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        console.log("1.7");
        console.log("amount0Out :- ",amount0Out);
        console.log("amount1Out :- ",amount1Out);

        // need to pass some data to trigger uniswapv2call
        bytes memory data = abi.encode(_tokenBorrow, _amount);
        console.log("1.8");
        console.log("TokenA before flashswap :- ",IERC20(_tokenBorrow).balanceOf(address(this)));
        console.log("TokenB before Swapping :- ",IERC20(TokenB).balanceOf(address(this)));
        console.log("TokenC before flashswap :- ",IERC20(TokenC).balanceOf(address(this)));
        beforeFlashBalA = IERC20(_tokenBorrow).balanceOf(address(this));
        beforeFlashBalB = IERC20(TokenB).balanceOf(address(this));
        beforeFlashBalC = IERC20(TokenC).balanceOf(address(this));
        // last parameter tells whether its a normal swap or a flash swap
        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
        console.log("1.9");
        // adding data triggers a flashloan
        }
    }

    // in return of flashloan call, uniswap will return with this function
    // providing us the token borrow and the amount
    function uniswapV2Call(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        // check msg.sender is the pair contract
        // take address of token0 n token1
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        // call uniswapv2factory to getpair 
        address pair = IUniswapV2Factory(UniswapV2Factory).getPair(token0, token1);
        console.log("Pool A/B Pair address :- ",pair);
        require(msg.sender == pair, "Not Pair");
        // check sender holds the address who initiated the flash loans
        require(_sender == address(this), "Not Sender");

        (address tokenBorrow, uint amount) = abi.decode(_data, (address, uint));
        uint amountReceived = (IERC20(tokenBorrow).balanceOf(address(this))) - beforeFlashBalA;
        console.log("TokenA receive after flashswap :- ",amountReceived);

        //swap borrowedamount A for tokenC from A/C
        address[] memory path;
        path = new address[](2);
        path[0] = TokenA;
        path[1] = TokenC;
        uint[] memory amountsC = IUniswapV2Router(UniswapV2Router).swapExactTokensForTokens(amountReceived, amountReceived, path, address(this), 1692742340);
        uint amountC = amountsC[1];
        console.log("amountsC[0][1] after exchange",amountsC[0],amountC);
        console.log("Token C receive after swapping :- ",(IERC20(TokenC).balanceOf(address(this)))-beforeFlashBalC);

        //swap tokenC for tokenB from B/C
        path[0] = TokenC;
        path[1] = TokenB;
        uint[] memory amountsB = IUniswapV2Router(UniswapV2Router).swapExactTokensForTokens(amountC, amountC, path, address(this), 1692742340); 
        uint amountB = amountsB[1];
        console.log("amountsB[0][1] after exchange",amountsB[0],amountB);
        //swap tokenB for tokenA from B/A
        path[0] = TokenA;
        path[1] = TokenB;
        uint[] memory B = IUniswapV2Router(UniswapV2Router).getAmountsIn(amount, path);
        console.log("Max of out TokenB :- ", B[0]);
        console.log("Min of out TokenB :- ", B[1]);
        IERC20(TokenB).transfer(pair, B[0]);
    }
}