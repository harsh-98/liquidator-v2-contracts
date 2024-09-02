// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.10;

import {AbstractLiquidator, LiquidationResult, IntermediateData} from "./AbstractLiquidator.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {GhoFMTaker} from "./GhoFMTaker.sol";

contract GhoLiquidator is AbstractLiquidator {
    using SafeERC20 for IERC20;

    bytes32 public constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    address public immutable ghoFlashMinter;
    address public immutable ghoFMTaker;
    address public immutable gho;

    modifier onlyGhoFlashMinter() {
        if (msg.sender != ghoFlashMinter) revert("Caller not GHO flash minter");
        _;
    }

    constructor(address _router, address _plb, address _ghoFlashMinter, address _ghoFMTaker, address _gho)
        AbstractLiquidator(_router, _plb)
    {
        ghoFlashMinter = _ghoFlashMinter;
        ghoFMTaker = _ghoFMTaker;
        gho = _gho;
    }

    function _takeFlashLoan(address, uint256 amount, bytes memory data) internal virtual override {
        GhoFMTaker(ghoFMTaker).takeFlashMint(amount, data);
    }

    function onFlashLoan(address initiator, address token, uint256 amount, uint256 fee, bytes calldata data)
        external
        onlyGhoFlashMinter
        returns (bytes32)
    {
        if (initiator != ghoFMTaker) revert("Flash loan initiator is not FMTaker");

        IntermediateData memory intData = abi.decode(data, (IntermediateData));

        _processFlashLoan(token, amount, fee, intData);

        IERC20(token).forceApprove(ghoFlashMinter, amount + fee);

        return CALLBACK_SUCCESS;
    }
}
