// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BaseV1 } from "../bases/BaseV1.sol";

/**
 * @title Mitos.
 * @author PAI3 Team.
 * @notice Mitos NFT collection.
 */
contract Mitos is BaseV1 {
    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns ownership and initializes variables.
     * @param owner_ Address of the contract owner.
     * @param feeWallet_ Address of the fee wallet.
     * @param baseURI_ Base URI for computing the {tokenURI}.
     * @param tokens_ Addresses of the tokens to be registered as payment
     * tokens.
     * @param priceFeeds_ Addresses of the price feed oracles relevant to a
     * registered payment token.
     */
    constructor(
        address owner_,
        address feeWallet_,
        string memory baseURI_,
        IERC20[] memory tokens_,
        AggregatorV3Interface[] memory priceFeeds_
    )
        BaseV1(
            owner_,
            "Mitos",
            "MIS",
            feeWallet_,
            100,
            baseURI_,
            tokens_,
            priceFeeds_,
            50_000
        )
    {}
}
