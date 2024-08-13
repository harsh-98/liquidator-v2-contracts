// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.17;

import {Balance} from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";
import {MultiCall} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import {PathOption} from "./IRouterV3.sol";

struct PriceUpdate {
    address token;
    bool reserve;
    bytes data;
}

struct RouterLiqParams {
    address creditAccount;
    Balance[] expectedBalances;
    Balance[] leftoverBalances;
    address[] connectors;
    uint256 slippage;
    PathOption[] pathOptions;
    uint256 iterations;
    bool force;
    PriceUpdate[] priceUpdates;
}

struct LiqParams {
    address creditFacade;
    address creditAccount;
    MultiCall[] calls;
}

struct LiquidationResult {
    address creditAccount;
    bool pathFound;
    bool executed;
    uint256 profit;
    MultiCall[] calls;
}

interface IBatchLiquidator {
    function estimateBatch(RouterLiqParams[] calldata params) external returns (LiquidationResult[] memory results);
    function liquidateBatch(LiqParams[] calldata params, address to) external returns (bool[] memory success);
}
