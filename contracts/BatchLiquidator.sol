// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Foundation, 2024
pragma solidity ^0.8.10;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@1inch/solidity-utils/contracts/libraries/SafeERC20.sol";

import {IRouterV3, RouterResult} from "./interfaces/IRouterV3.sol";
import {
    IBatchLiquidator,
    RouterLiqParams,
    LiquidationResult,
    LiqParams,
    PriceUpdate
} from "./interfaces/IBatchLiquidator.sol";
import {ICreditAccountV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditAccountV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {ICreditFacadeV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {ICreditFacadeV3Multicall} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditFacadeV3Multicall.sol";
import {MultiCall, MultiCallOps} from "@gearbox-protocol/core-v2/contracts/libraries/MultiCall.sol";
import {Balance} from "@gearbox-protocol/core-v2/contracts/libraries/Balances.sol";
import {IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";

contract BatchLiquidator is Ownable {
    using SafeERC20 for IERC20;
    using MultiCallOps for MultiCall[];

    event SetWhitelistedStatus(address indexed account, bool status);

    mapping(address => bool) public isWhitelisted;

    address public router;

    constructor(address _router) {
        router = _router;
        isWhitelisted[_msgSender()] = true;
    }

    modifier whitelistedOnly() {
        if (!isWhitelisted[msg.sender]) revert("Caller not whitelisted");
        _;
    }

    function estimateBatch(RouterLiqParams[] calldata params)
        external
        whitelistedOnly
        returns (LiquidationResult[] memory results)
    {
        uint256 len = params.length;

        results = new LiquidationResult[](len);

        for (uint256 i = 0; i < len;) {
            _applyOnDemandPriceUpdates(params[i].creditAccount, params[i].priceUpdates);

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

    function liquidateBatch(LiqParams[] calldata params, address to)
        external
        whitelistedOnly
        returns (bool[] memory success)
    {
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

    function _getPriceOracle(address creditAccount) internal view returns (address priceOracle) {
        address creditManager = ICreditAccountV3(creditAccount).creditManager();
        priceOracle = ICreditManagerV3(creditManager).priceOracle();
    }

    /// @dev Applies on-demand price feed updates, reverts if trying to update unknown price feeds
    function _applyOnDemandPriceUpdates(address creditAccount, PriceUpdate[] calldata priceUpdates) internal {
        address priceOracle = _getPriceOracle(creditAccount);

        uint256 len = priceUpdates.length;
        for (uint256 i; i < len; ++i) {
            PriceUpdate calldata update = priceUpdates[i];
            address priceFeed = IPriceOracleV3(priceOracle).priceFeedsRaw(update.token, update.reserve);
            if (priceFeed == address(0)) revert("Price feed does not exist");
            IUpdatablePriceFeed(priceFeed).updatePrice(update.data);
        }
    }

    function setWhitelistedStatus(address account, bool status) external onlyOwner {
        if (isWhitelisted[account] != status) {
            isWhitelisted[account] = status;
            emit SetWhitelistedStatus(account, status);
        }
    }
}
