// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.17;

import {IPartialLiquidationBotV3} from "@gearbox-protocol/bots-v3/contracts/interfaces/IPartialLiquidationBotV3.sol";
import {MultiCall} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";

struct LiquidationResult {
    MultiCall[] calls;
    int256 profit;
    uint256 amountIn;
    uint256 amountOut;
}

interface ILiquidator {
    function router() external view returns (address);
    function partialLiquidationBot() external view returns (address);
    function cmToCA(address cm) external view returns (address);

    function partialLiquidateAndConvert(
        address creditManager,
        address creditAccount,
        address assetOut,
        uint256 amountOut,
        uint256 flashLoanAmount,
        IPartialLiquidationBotV3.PriceUpdate[] calldata priceUpdates,
        MultiCall[] calldata conversionCalls
    ) external;

    function previewPartialLiquidation(
        address creditManager,
        address creditAccount,
        address assetOut,
        uint256 amountOut,
        uint256 flashLoanAmount,
        IPartialLiquidationBotV3.PriceUpdate[] calldata priceUpdates,
        address[] calldata connectors,
        uint256 slippage
    ) external returns (LiquidationResult memory res);

    function getOptimalLiquidation(
        address creditAccount,
        uint256 hfOptimal,
        IPartialLiquidationBotV3.PriceUpdate[] calldata priceUpdates
    )
        external
        returns (
            address tokenOut,
            uint256 optimalAmount,
            uint256 repaidAmount,
            uint256 flashLoanAmount,
            bool isOptimalRepayable
        );

    function registerCM(address creditManager) external;

    function withdrawToken(address token, uint256 amount, address to) external;

    function setRouter(address newRouter) external;

    function setPartialLiquidationBot(address newPLB) external;
}
