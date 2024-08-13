// SPDX-License-Identifier: GPL-2.0-or-later
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.8.17;

struct TokenPriceInfo {
    address token;
    uint256 balance;
    uint256 balanceInUnderlying;
    uint256 liquidationThreshold;
}

struct PriceOnDemand {
    address token;
    bytes callData;
}

interface IPriceHelper {
    function previewTokens(address creditAccount, PriceOnDemand[] memory priceUpdates)
        external
        returns (TokenPriceInfo[] memory results);
}
