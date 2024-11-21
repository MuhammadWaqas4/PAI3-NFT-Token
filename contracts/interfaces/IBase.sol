// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

import { IPAI3 } from "./IPAI3.sol";

/**
 * @title IBase.
 * @author Muhammad Waqas.
 * @notice Base NFT collection interface.
 */
interface IBase is IERC721A {
    enum Phase {
        FIRST,
        SECOND
    }

    /**
     * @dev Emitted when {baseURI} is changed from `oldBaseURI` to `newBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts ETH as a payment method. Can only be called when
     * `unpaused`.
     * @param quantity Amount of tokens to purchase.
     */
    function purchaseETH(uint256 quantity) external payable;

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts registered ERC20 tokens as a payment method. Can only
     * be called when `unpaused`.
     * @param token Token to use as a payment method.
     * @param quantity Amount of tokens to purchase.
     */
    function purchase(IERC20 token, uint256 quantity) external;

    /**
     * @notice Sets the value for {baseURI}.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(string memory newBaseURI) external returns (bool);

    /**
     * @notice Changes the state of the contract from `paused` to `unpaused`
     * after the first phase has ended and bumps the phase.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `paused`.
     */
    function bumpPhase() external;

    /**
     * @notice Arbitrary checksummed address to signify ETH.
     */
    function ETH() external view returns (IERC20);

    /**
     * @notice Address of the fee wallet.
     */
    function FEE_WALLET() external view returns (address);

    /**
     * @notice Time period until NFTs are vested.
     */
    function VESTING_DEADLINE() external view returns (uint256);

    /**
     * @notice Base cost for a single NFT.
     */
    function BASE_COST_SINGLE() external view returns (uint256);

    /**
     * @notice Current phase.
     */
    function phase() external view returns (Phase);

    /**
     * @notice Base URI for computing {tokenURI}. If set, the resulting URI for
     * each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Address of the price feed oracle relevant to a registered payment
     * token.
     * @param token Address of the registered payment token.
     */
    function priceFeeds(
        IERC20 token
    ) external view returns (AggregatorV3Interface);

    /**
     * @notice Cap on the token's total supply.
     */
    function cap() external view returns (uint256);
}
