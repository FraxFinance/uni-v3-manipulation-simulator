// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import { Logger } from "frax-std/Logger.sol";
import { IUniswapV3Pool } from "../src/interfaces/IUniswapV3Pool.sol";

contract TestUniswapV3Price is FraxTest {
    IUniswapV3Pool public pool = IUniswapV3Pool(0x36C060Cc4b088c830a561E959A679A58205D3F56);
    ISwapRouter public swapRouter = ISwapRouter(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address public constant FRXETH_ERC20 = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant FRAX_ERC20 = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    uint24 public fee = 10000;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_URL"));
    }

    function testSimulateBuyFrxEth(uint256 _amount) internal {
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            FRXETH_ERC20,
            FRAX_ERC20,
            fee,
            address(this),
            block.timestamp,
            _amount,
            0,
            0
        );
        uint256 _amountOut = swapRouter.exactInputSingle(params);
        vm.warp(block.timestamp + 12);
        vm.roll(block.number + 1);
        address[] memory pools = new address[](1);
        pools[0] = address(pool);

        uint256 _price1 = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod(
            1e18,
            FRXETH_ERC20,
            FRAX_ERC20,
            pools,
            900
        );
        Logger.decimal("Frax Ether Price in Frax Terms", _price1, 1e18);
    }
}
