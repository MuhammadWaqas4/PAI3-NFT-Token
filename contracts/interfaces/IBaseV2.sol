// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

import { IPAI3 } from "./IPAI3.sol";

/**
 * @title IBaseV2.
 * @author PAI3 Team.
 * @notice BaseV2 NFT collection interface.
 */
interface IBaseV2 is IERC721A {
    /* ========== TYPES ========== */

    enum Phase {
        FIRST,
        SECOND
    }

    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when `quantity` tokens are minted by `minter`.
     */
    event Mint(
        address indexed minter,
        IERC20 token,
        uint256 fromTokenId,
        uint256 quantity,
        uint256 cost
    );

    /**
     * @dev Emitted when {baseURI} is changed to `newBaseURI` from `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @dev Emitted when {signer} is changed to `newSigner` from `oldSigner`.
     */
    event UpdateSigner(address indexed newSigner, address indexed oldSigner);

    /**
     * @dev Emitted when {priceFeed} of the `token` is changed to `newPriceFeed`
     * from `oldPriceFeed`.
     */
    event UpdatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed,
        AggregatorV3Interface oldPriceFeed
    );

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts ETH as a payment method. Can only be called when
     * `unpaused`.
     * @param quantity Amount of tokens to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function mintETH(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts registered ERC20 tokens as a payment method. Can only
     * be called when `unpaused`.
     * @param token Token to use as a payment method.
     * @param quantity Amount of tokens to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function mint(
        IERC20 token,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @notice Sets the value for {baseURI}.
     * NOTE: Only `owner` can call this function.
     * @param newBaseURI Value to set the {baseURI} to.
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Updates the address of the ECDSA {signer}.
     * NOTE: Only `owner` can call this function.
     * @param newSigner Address of the new data signer.
     */
    function updateSigner(address newSigner) external;

    /**
     * @notice Adds, removes or updates the price feed oracle of a given
     * `token`.
     * NOTE: Only `owner` can call this function.
     * @param token Address of the token.
     * @param newPriceFeed Price feed oracle to add, remove or update for the
     * given token.
     */
    function updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed
    ) external;

    /**
     * @notice Changes the state of the contract from `paused` to `unpaused`
     * after the first phase has ended and bumps the phase.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `paused`.
     */
    function bumpPhase() external;

    /**
     * @notice Change the state of the contract from unpaused to paused.
     * NOTE: Only `owner` can call this function.
     */
    function pause() external;

    /**
     * @notice Change the state of the contract from paused to unpaused.
     * NOTE: Only `owner` can call this function.
     */
    function unpause() external;

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
     * @notice Address of the ECDSA signer.
     */
    function signer() external view returns (address);

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
