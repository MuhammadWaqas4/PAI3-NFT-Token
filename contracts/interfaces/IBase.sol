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
    /**
     * @dev Emitted when {baseURI} is changed from `oldBaseURI` to `newBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @notice Base fee in USD to be collected per token being minted.
     */
    function BASE_MINT_FEE() external view returns (uint256);

    /**
     * @notice Cap on the token's total supply.
     */
    function CAP() external view returns (uint256);

    /**
     * @notice Address of the funds collection wallet.
     */
    function FUNDS_WALLET() external view returns (address);

    /**
     * @notice Address of the Tether USD token.
     */
    function USDT() external view returns (IERC20);

    /**
     * @notice Base URI for computing {tokenURI}. If set, the resulting URI for
     * each token will be the concatenation of the `baseURI` and the `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Addresses of the price feed oracles.
     */
    function priceFeeds(
        IERC20 token
    ) external view returns (AggregatorV3Interface);

    /**
     * @notice Sets the value for {baseURI}.
     * NOTE: Only `Owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(string memory newBaseURI) external returns (bool);

    /**
     * @notice Safely mints `quantity` tokens and transfers them to `to`.
     * NOTE: Requires funds at the time of calling. Accepts ETH if given
     * otherwise uses a dedicated token.
     * @param token Token to use for minting fees.
     * @param to Recipient address of minted tokens.
     * @param quantity Amount of tokens to mint.
     */
    function safeMint(
        IERC20 token,
        address to,
        uint256 quantity
    ) external payable returns (bool);
}
