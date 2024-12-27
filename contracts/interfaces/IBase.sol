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
    /* ========== TYPES ========== */

    struct Record {
        uint64 startTimestamp;
        uint64 vestingEndTimestamp;
        uint64 rewardingEndTimestamp;
        uint64 lastInteractedTimestamp;
    }

    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when `quantity` of `tokens` is minted by `minter`.
     */
    event Mint(
        address indexed minter,
        IERC20 token,
        uint256 startTokenId,
        uint256 quantity,
        uint256 cost
    );

    /**
     * @dev Emitted when reward relevant to a `tokenId` is claimed by `claimer`.
     */
    event Claim(
        address indexed claimer,
        uint256 tokenId,
        uint256 reward,
        uint256 due
    );

    /**
     * @dev Emitted when {signer} is changed to `newSigner` from `oldSigner`.
     */
    event UpdateSigner(address indexed newSigner, address indexed oldSigner);

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
     * @notice Mints `quantity` of `tokens` and transfers them to the `caller`.
     * NOTE: `Payable value` must be given. Only accepts `ETH` as a payment
     * method.
     * @param quantity Amount of tokens to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function mintWithETH(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mints `quantity` of `tokens` and transfers them to the `caller`.
     * NOTE: Only accepts a registered ERC20 `token` as a payment method.
     * @param token ERC20 token to use as a payment method.
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
     * @notice Transfers rewards collected by the user relevant to a `tokenId`.
     * @param tokenId Unique identifier of the token.
     */
    function claim(uint256 tokenId) external;

    /**
     * @notice Updates the address of the `signature` {signer}.
     * NOTE: Only `owner` can call this function.
     * @param newSigner Address of the new data signer.
     */
    function updateSigner(address newSigner) external;

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
     * @notice Vesting duration in seconds.
     */
    function VESTING_DURATION() external view returns (uint64);

    /**
     * @notice Reward duration in seconds.
     */
    function REWARD_DURATION() external view returns (uint64);

    /**
     * @notice Reward generated per second.
     */
    function REWARD_PER_SECOND() external view returns (uint256);

    /**
     * @notice Base cost for a single token.
     */
    function BASE_COST_SINGLE() external view returns (uint256);

    /**
     * @notice Address of the PAI3 token.
     */
    function PAI3() external view returns (IERC20);

    /**
     * @notice Address of the fee wallet.
     */
    function FEE_WALLET() external view returns (address);

    /**
     * @notice Address of the reward wallet.
     */
    function REWARD_WALLET() external view returns (address);

    /**
     * @notice Address of the signature signer.
     */
    function signer() external view returns (address);

    /**
     * @notice `Base URI` for computing {tokenURI}. If set, the resulting URI
     * for each `token` will be the concatenation of the `base URI` and the
     * `tokenId`.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Time based `records` relevant to a `tokenId`.
     * @param tokenId Unique identifier of the token.
     * @return record Complete time based record of the token.
     */
    function tokenRecords(
        uint256 tokenId
    ) external view returns (Record memory);

    /**
     * @notice Address of the `price feed` relevant to a registered payment
     * `token`.
     * @param token Address of the registered payment token.
     * @return priceFeed Address of the price feed.
     */
    function priceFeeds(
        IERC20 token
    ) external view returns (AggregatorV3Interface);

    /**
     * @notice Due rewards relevant to an `account`.
     * @param account Account address of the user.
     * @return due Due rewards of the user.
     */
    function dues(address account) external view returns (uint256);
}
