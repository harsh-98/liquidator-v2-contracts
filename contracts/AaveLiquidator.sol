// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.10;

import {AbstractLiquidator, LiquidationResult, IntermediateData} from "./AbstractLiquidator.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {AaveFLTaker} from "./AaveFLTaker.sol";

contract AaveLiquidator is AbstractLiquidator {
    using SafeERC20 for IERC20;

    address public immutable aavePool;
    address public immutable aaveFLTaker;

    modifier onlyAave() {
        if (msg.sender != aavePool) revert("Caller not Aave pool");
        _;
    }

    constructor(address _router, address _plb, address _aavePool, address _aaveFLTaker)
        AbstractLiquidator(_router, _plb)
    {
        aavePool = _aavePool;
        aaveFLTaker = _aaveFLTaker;
    }

    function _takeFlashLoan(address underlying, uint256 amount, bytes memory data) internal virtual override {
        AaveFLTaker(aaveFLTaker).takeFlashLoan(underlying, amount, data);
    }

    function executeOperation(
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory premiums,
        address initiator,
        bytes calldata params
    ) external onlyAave returns (bool) {
        if (initiator != aaveFLTaker) revert("Flash loan initiator is not FLTaker");

        IntermediateData memory intData = abi.decode(params, (IntermediateData));

        _processFlashLoan(assets[0], amounts[0], premiums[0], intData);

        IERC20(assets[0]).forceApprove(aavePool, amounts[0] + premiums[0]);
        return true;
    }
}
