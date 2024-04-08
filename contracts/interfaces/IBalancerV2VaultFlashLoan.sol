// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.17;

interface IBalancerV2VaultFlashLoan {
    function flashLoan(address recipient, address[] memory tokens, uint256[] memory amounts, bytes memory userData)
        external;
}
