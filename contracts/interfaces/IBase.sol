// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

/**
 * @title IBase.
 * @author PAI3 Team.
 * @notice Base NFT collection interface.
 */
interface IBase is IERC721A {
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when `base URI` is changed to `newBaseURI` from
     * `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @dev Emitted when `price feed` of a `token` is changed to `newPriceFeed`
     * from `oldPriceFeed`.
     */
    event UpdatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed,
        AggregatorV3Interface oldPriceFeed
    );

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Sets the value for `base URI`.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the base URI to.
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Adds, removes or updates the `price feed` of a given `token`.
     * NOTE: Only `owner` can call this function.
     * @param token Address of the token.
     * @param newPriceFeed Price feed to add, remove or update for the
     * given token.
     */
    function updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed
    ) external;

    /**
     * @notice Address of the fee wallet.
     */
    function FEE_WALLET() external view returns (address);

    /**
     * @notice Time period until `tokens` are vested.
     */
    function VESTING_EXPIRY() external view returns (uint256);

    /**
     * @notice Base cost for a single `token`.
     */
    function BASE_COST_SINGLE() external view returns (uint256);

    /**
     * @notice `Base URI` for computing {tokenURI}. If set, the resulting URI
     * for each `token` will be the concatenation of the `base URI` and the
     * `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Address of the `price feed` relevant to a registered payment
     * `token`.
     * @param token Address of the registered payment token.
     */
    function priceFeeds(
        IERC20 token
    ) external view returns (AggregatorV3Interface);
}
