// SPDX-License-Identifier: ISC
pragma solidity ^0.8.19;

import "frax-std/FraxTest.sol";
import { Logger } from "frax-std/Logger.sol";
import { TestHelper } from "frax-std/TestHelper.sol";
import { IStaticOracle } from "@mean-finance/uniswap-v3-oracle/solidity/interfaces/IStaticOracle.sol";
import { IUniswapV3Pool } from "../src/interfaces/IUniswapV3Pool.sol";
import { ISwapRouter02 } from "../src/interfaces/ISwapRouter02.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestUniswapV3Price is FraxTest, TestHelper {
    IUniswapV3Pool public pool = IUniswapV3Pool(0x36C060Cc4b088c830a561E959A679A58205D3F56);
    ISwapRouter02 public swapRouter = ISwapRouter02(0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45);
    address public constant FRXETH_ERC20 = 0x5E8422345238F34275888049021821E8E08CAa1f;
    address public constant FRAX_ERC20 = 0x853d955aCEf822Db058eb8505911ED77F175b99e;
    address public constant SFRAX_VAULT = 0xac3E018457B222d93114458476f3E3416Abbe38F;
    uint24 public fee = 10000;

    function setUp() public {
        vm.createSelectFork(vm.envString("MAINNET_URL"), 17_190_794);
        // NOTE: uncomment this line to use the latest block but this will hog your API keys
        // vm.createSelectFork(vm.envString("MAINNET_URL"));
    }

    function testSimulateSellFrxEth() public {
        // Configure this amount as needed
        uint256 _amount = 10000e18;
        uint256 _blocksToMine = 1;

        // Define the pools to check twap on
        address[] memory pools = new address[](1);
        pools[0] = address(pool);

        // Get initial Price
        uint256 _price0 = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: 1e18,
            baseToken: FRXETH_ERC20,
            quoteToken: FRAX_ERC20,
            pools: pools,
            period: 900
        });

        // Log the initial price using 1e18 precision
        Logger.decimal("Initial FraxEther Price in Frax Terms:", _price0, 1e18);

        // The params for buying
        ISwapRouter02.ExactInputSingleParams memory params = ISwapRouter02.ExactInputSingleParams({
            tokenIn: FRXETH_ERC20,
            tokenOut: FRAX_ERC20,
            fee: fee,
            recipient: SFRAX_VAULT,
            amountIn: _amount,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        // Simulate the buy as the frax ferry which has a lot of FRXETH
        startHoax(SFRAX_VAULT);
        IERC20(FRXETH_ERC20).approve(address(swapRouter), _amount);
        swapRouter.exactInputSingle(params);

        // Move forward in time for TWAP calcs
        mineBlocks(_blocksToMine);

        uint256 _price1 = IStaticOracle(0xB210CE856631EeEB767eFa666EC7C1C57738d438).quoteSpecificPoolsWithTimePeriod({
            baseAmount: 1e18,
            baseToken: FRXETH_ERC20,
            quoteToken: FRAX_ERC20,
            pools: pools,
            period: 900
        });

        // Log the final price using 1e18 precision
        Logger.decimal("  Final FraxEther Price in Frax Terms:", _price1, 1e18);
    }
}
