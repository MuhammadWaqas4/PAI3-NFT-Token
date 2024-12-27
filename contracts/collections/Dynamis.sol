// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BaseV2 } from "../bases/BaseV2.sol";

/**
 * @title Dynamis.
 * @author PAI3 Team.
 * @notice Dynamis NFT collection.
 */
contract Dynamis is BaseV2 {
    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param owner_ Address of the contract owner.
     * @param pai3_ Address of the PAI3 token.
     * @param feeWallet_ Address of the fee wallet.
     * @param rewardWallet_ Address of the reward wallet.
     * @param signer_ Address of the signatrue signer.
     * @param baseURI_ Base URI for computing the tokenURI.
     * @param tokens_ Addresses of the tokens to register as payment tokens.
     * @param priceFeeds_ Addresses of the price feeds.
     */
    constructor(
        address owner_,
        IERC20 pai3_,
        address feeWallet_,
        address rewardWallet_,
        address signer_,
        string memory baseURI_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    )
        BaseV2(
            owner_,
            "Dynamis",
            "DYS",
            31_449_600,
            0.000921665140415140 * 1e18,
            1_000,
            pai3_,
            feeWallet_,
            rewardWallet_,
            signer_,
            baseURI_,
            tokens_,
            priceFeeds_,
            100,
            10_000
        )
    {}
}
