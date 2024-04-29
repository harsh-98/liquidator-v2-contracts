// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.17;

import {Balance} from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";
import {MultiCall} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";

struct PathOption {
    address target;
    uint8 option;
    uint8 totalOptions;
}

struct RouterResult {
    uint256 amount;
    uint256 minAmount;
    MultiCall[] calls;
}

interface IRouterV3 {
    function findOneTokenPath(
        address tokenIn,
        uint256 amount,
        address tokenOut,
        address creditAccount,
        address[] calldata connectors,
        uint256 slippage
    ) external returns (RouterResult memory);

    function findBestClosePath(
        address creditAccount,
        Balance[] calldata expectedBalances,
        Balance[] calldata leftoverBalances,
        address[] memory connectors,
        uint256 slippage,
        PathOption[] memory pathOptions,
        uint256 iterations,
        bool force
    ) external returns (RouterResult memory result);
}
