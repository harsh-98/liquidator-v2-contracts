// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2024
pragma solidity ^0.8.10;

import {IPriceHelper, PriceOnDemand, TokenPriceInfo} from "./interfaces/IPriceHelper.sol";
import {ICreditAccountV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditAccountV3.sol";
import {ICreditManagerV3} from "@gearbox-protocol/core-v3/contracts/interfaces/ICreditManagerV3.sol";
import {IPriceOracleV3} from "@gearbox-protocol/core-v3/contracts/interfaces/IPriceOracleV3.sol";
import {IPriceFeed, IUpdatablePriceFeed} from "@gearbox-protocol/core-v2/contracts/interfaces/IPriceFeed.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@gearbox-protocol/core-v3/contracts/interfaces/IExceptions.sol";

contract PriceHelper is IPriceHelper {
    function previewTokens(address creditAccount, PriceOnDemand[] memory priceUpdates)
        external
        returns (TokenPriceInfo[] memory results)
    {
        ICreditManagerV3 creditManager = ICreditManagerV3(ICreditAccountV3(creditAccount).creditManager());
        address oracle = creditManager.priceOracle();

        _updatePrices(oracle, priceUpdates);

        address underlying = creditManager.underlying();
        uint256 underlyingScale = 10 ** IERC20Metadata(underlying).decimals();
        uint256 enabledTokensMask = creditManager.enabledTokensMaskOf(creditAccount);
        uint256 priceTo = _unsafeGetPrice(oracle, underlying);

        uint256 len = creditManager.collateralTokensCount();
        uint256 cnt = 0;
        TokenPriceInfo[] memory tmp = new TokenPriceInfo[](len);
        unchecked {
            for (uint256 i = 0; i < len; ++i) {
                TokenPriceInfo memory info = TokenPriceInfo(address(0), 0, 0, 0);
                (info.token, info.liquidationThreshold) = creditManager.collateralTokenByMask(1 << i);
                info.balance = IERC20(info.token).balanceOf(creditAccount);
                uint256 tokenMask = 1 << i;
                uint256 tokenScale = 10 ** IERC20Metadata(info.token).decimals();
                if (info.balance > 10 && tokenMask & enabledTokensMask != 0) {
                    if (info.token == underlying) {
                        info.balanceInUnderlying = info.balance;
                    } else {
                        uint256 priceFrom = _unsafeGetPrice(oracle, info.token);
                        info.balanceInUnderlying = info.balance * priceFrom * underlyingScale / (priceTo * tokenScale);
                    }
                    tmp[cnt] = info;
                    cnt++;
                }
            }
        }

        results = new TokenPriceInfo[](cnt);
        unchecked {
            for (uint256 i = 0; i < cnt; ++i) {
                results[i] = tmp[i];
            }
        }
    }

    function _updatePrices(address priceOracle, PriceOnDemand[] memory priceUpdates) internal {
        IPriceOracleV3 oracle = IPriceOracleV3(priceOracle);
        uint256 len = priceUpdates.length;
        unchecked {
            for (uint256 i; i < len; ++i) {
                address priceFeed = oracle.priceFeeds(priceUpdates[i].token);
                if (priceFeed == address(0)) {
                    revert PriceFeedDoesNotExistException();
                }
                IUpdatablePriceFeed(priceFeed).updatePrice(priceUpdates[i].callData);
            }
        }
    }

    /// @dev Returns price feed answer while trying to ignore revert that can happen due to unupdated PULL oracles
    function _unsafeGetPrice(address oracle, address token) internal view returns (uint256 price) {
        IPriceOracleV3 priceOracle = IPriceOracleV3(oracle);

        // check main price feed
        IPriceFeed priceFeed = IPriceFeed(priceOracle.priceFeedsRaw(token, false));
        try priceFeed.latestRoundData() returns (uint80, int256 answer, uint256, uint256, uint80) {
            price = uint256(answer);
        } catch {
            // Try reserve price feed
            priceFeed = IPriceFeed(priceOracle.priceFeedsRaw(token, true));
            (, int256 answer,,,) = priceFeed.latestRoundData();
            price = uint256(answer);
        }
    }
}
