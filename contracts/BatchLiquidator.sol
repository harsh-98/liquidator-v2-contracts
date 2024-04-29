// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {IRouterV3, RouterResult} from "./interfaces/IRouterV3.sol";
import {IBatchLiquidator, RouterLiqParams, LiquidationResult, LiqParams} from "./interfaces/IBatchLiquidator.sol";
import {ICreditAccountV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditAccountV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {ICreditFacadeV3Multicall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3Multicall.sol";
import {MultiCall, MultiCallOps} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import {Balance} from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";

contract BatchLiquidator is IBatchLiquidator {
    using SafeERC20 for IERC20;
    using MultiCallOps for MultiCall[];

    address public router;

    constructor(address _router) {
        router = _router;
    }

    function estimateBatch(RouterLiqParams[] calldata params) external returns (LiquidationResult[] memory results) {
        uint256 len = params.length;

        results = new LiquidationResult[](len);

        for (uint256 i = 0; i < len;) {
            results[i].creditAccount = params[i].creditAccount;

            (bool pathSuccess, RouterResult memory res) = _findBestClosePath(params[i]);

            if (pathSuccess) {
                results[i].pathFound = true;
                results[i].calls = res.calls;

                (address creditFacade, address underlying) = _getCreditFacade(params[i].creditAccount);

                uint256 bal = IERC20(underlying).balanceOf(address(this));

                try ICreditFacadeV3(creditFacade).liquidateCreditAccount(
                    params[i].creditAccount, address(this), res.calls
                ) {
                    results[i].executed = true;
                    results[i].profit = IERC20(underlying).balanceOf(address(this)) - bal;
                } catch {}
            }

            unchecked {
                ++i;
            }
        }
    }

    function liquidateBatch(LiqParams[] calldata params, address to) external returns (bool[] memory success) {
        uint256 len = params.length;

        success = new bool[](len);

        for (uint256 i = 0; i < len;) {
            try ICreditFacadeV3(params[i].creditFacade).liquidateCreditAccount(
                params[i].creditAccount, to, params[i].calls
            ) {
                success[i] = true;
            } catch {}

            unchecked {
                ++i;
            }
        }
    }

    function _findBestClosePath(RouterLiqParams memory params)
        internal
        returns (bool success, RouterResult memory res)
    {
        try IRouterV3(router).findBestClosePath(
            params.creditAccount,
            params.expectedBalances,
            params.leftoverBalances,
            params.connectors,
            params.slippage,
            params.pathOptions,
            params.iterations,
            params.force
        ) returns (RouterResult memory _res) {
            success = true;
            res = _res;
        } catch {}
    }

    function _getCreditFacade(address creditAccount) internal view returns (address cf, address underlying) {
        address creditManager = ICreditAccountV3(creditAccount).creditManager();
        cf = ICreditManagerV3(creditManager).creditFacade();
        underlying = ICreditManagerV3(creditManager).underlying();
    }
}
