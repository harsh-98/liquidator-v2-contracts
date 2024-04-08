// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.17;

import {MultiCall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";

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
}
