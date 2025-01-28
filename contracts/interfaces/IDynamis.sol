// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IERC721A } from "erc721a/contracts/IERC721A.sol";

/**
 * @title IDynamis.
 * @author PAI3 Team.
 * @notice Dynamis NFT collection interface.
 */
interface IDynamis is IERC721A {
    /* ========================== TYPES ========================== */

    enum Phase {
        PREMINT,
        FIRST,
        SECOND,
        THIRD,
        FOURTH,
        FIFTH
    }

    struct DynamisParams {
        /// @custom:member Address of the contract owner.
        address owner;
        /// @custom:member Token collection name.
        string name;
        /// @custom:member Token collection symbol.
        string symbol;
        /// @custom:member Base cost for a single token.
        uint256 baseCostSingle;
        /// @custom:member Cap on the number of minted tokens initially.
        uint256 initialCap;
        /// @custom:member Cap on the number of minted tokens.
        uint256 cap;
        /// @custom:member Address of the PAI3 token.
        IERC20 pai3;
        /// @custom:member Address of the treasury wallet.
        address treasuryWallet;
        /// @custom:member Address of the reward wallet.
        address rewardWallet;
        /// @custom:member Address of the signature signer.
        address signer;
        /// @custom:member Base URI for computing the tokenURI.
        string baseURI;
        /// @custom:member Addresses of the payment tokens.
        IERC20[] tokens;
        /// @custom:member Addresses of the price feeds.
        AggregatorV3Interface[] priceFeeds;
    }

    struct Record {
        /// @custom:member Timestamp at which a token was minted.
        uint64 startTimestamp;
        /// @custom:member Timestamp after which vesting will end.
        uint64 vestingEndTimestamp;
        /// @custom:member Timestamp after which reward generation will stop.
        uint64 rewardingEndTimestamp;
        /// @custom:member Timestamp at which a transfer was performed.
        uint64 lastInteractedTimestamp;
    }

    /* ========================== EVENTS ========================== */

    /**
     * @dev Emitted when `quantity` of NFTs is minted by `minter` starting from
     * `startTokenId` using `token` with the amount of `cost`.
     */
    event Mint(
        address indexed minter,
        IERC20 token,
        uint256 startTokenId,
        uint256 quantity,
        uint256 cost
    );

    /**
     * @dev Emitted when `reward` and `due` corresponding to a `tokenId` is
     * claimed by `claimer`.
     */
    event Claim(
        address indexed claimer,
        uint256 tokenId,
        uint256 reward,
        uint256 due
    );

    /**
     * @dev Emitted when signer is changed to `newSigner` from `oldSigner`.
     */
    event UpdateSigner(address indexed newSigner, address indexed oldSigner);

    /**
     * @dev Emitted when baseURI is changed to `newBaseURI` from `oldBaseURI`.
     */
    event SetBaseURI(string newBaseURI, string oldBaseURI);

    /**
     * @dev Emitted when the price feed of a `token` is changed to
     * `newPriceFeed` from `oldPriceFeed`.
     */
    event UpdatePriceFeed(
        IERC20 token,
        AggregatorV3Interface newPriceFeed,
        AggregatorV3Interface oldPriceFeed
    );

    /* ========================== FUNCTIONS ========================== */

    /**
     * @notice Mints NFTs with the amount of `quantity` and transfers them to
     * `caller`.
     * NOTE: Payable value must be given. Only accepts ETH as a payment method.
     * @param quantity Amount of NFTs to mint.
     * @param discountCostSingle Discounted base cost for a single token.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness in the case of a
     * discount.
     */
    function mintWithETH(
        uint256 quantity,
        uint256 discountCostSingle,
        uint256 deadline,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mints NFTs with the amount of `quantity` and transfers them to
     * `caller`.
     * NOTE: Only accepts `token` if it is registered as a payment method.
     * @param token Registered payment method.
     * @param quantity Amount of NFTs to mint.
     * @param discountCostSingle Discounted base cost for a single token.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness in the case of a
     * discount.
     */
    function mint(
        IERC20 token,
        uint256 quantity,
        uint256 discountCostSingle,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @notice Transfers rewards collected by the user relevant to a `tokenId`.
     * @param tokenId Unique identifier of the token.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function claim(
        uint256 tokenId,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @notice Bumps the phase after the first phase has ended and changes the
     * state of the contract from paused to unpaused.
     * NOTE: Only owner can call this function. Can only be called when paused.
     */
    function bumpPhase() external;

    /**
     * @notice Change the state of the contract from unpaused to paused.
     * NOTE: Only owner can call this function. Can only be called when
     * unpaused.
     */
    function pause() external;

    /**
     * @notice Change the state of the contract from paused to unpaused.
     * NOTE: Only owner can call this function. Can only be called when paused.
     */
    function unpause() external;

    /**
     * @notice Updates the address of the ECDSA signer.
     * NOTE: Only owner can call this function.
     * @param newSigner Address of the new ECDSA signer.
     */
    function updateSigner(address newSigner) external;

    /**
     * @notice Sets the value for base URI.
     * NOTE: Only owner can call this function.
     * @param newBaseURI Value to set the base URI to.
     */
    function setBaseURI(string memory newBaseURI) external;

    /**
     * @notice Adds, removes or updates the `priceFeed` of a given `token`.
     * NOTE: Only owner can call this function.
     * @param token Address of the payment method.
     * @param priceFeed Price feed to add, remove or update for the given
     * payment method.
     */
    function updatePriceFeed(
        IERC20 token,
        AggregatorV3Interface priceFeed
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
     * @notice Address of the treasury wallet.
     */
    function TREASURY_WALLET() external view returns (address);

    /**
     * @notice Address of the reward wallet.
     */
    function REWARD_WALLET() external view returns (address);

    /**
     * @notice Address of the signature signer.
     */
    function signer() external view returns (address);

    /**
     * @notice Base URI for computing tokenURI. If set, the resulting URI for
     * each token will be the concatenation of the base URI and the tokenId.
     */
    function baseURI() external view returns (string memory);

    /**
     * @notice Current phase.
     */
    function phase() external view returns (Phase);

    /**
     * @notice Cap on the token's totalSupply.
     */
    function cap() external view returns (uint256);

    /**
     * @notice Time based records relevant to a `tokenId`.
     * @param tokenId Unique identifier of the NFT.
     * @return record Complete time based record of the NFT.
     */
    function tokenRecords(
        uint256 tokenId
    ) external view returns (Record memory);

    /**
     * @notice Due rewards relevant to an `account`.
     * @param tokenId Unique identifier of the NFT.
     * @return due Due rewards not yet claimed.
     */
    function dues(uint256 tokenId) external view returns (uint256);

    /**
     * @notice Address of the price feed relevant to a registered payment
     * method.
     * @param token Address of the payment method.
     * @return priceFeed Address of the price feed.
     */
    function priceFeeds(
        IERC20 token
    ) external view returns (AggregatorV3Interface);
}
