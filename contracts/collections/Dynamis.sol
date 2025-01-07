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
     * @param params_ Params necessary for contract deployment.
     * @param initialCap_ Cap on the number of minted tokens initially.
     * @param cap_ Cap on the number of minted tokens.
     */
    constructor(
        BaseParams memory params_,
        uint256 initialCap_,
        uint256 cap_
    ) BaseV2(params_, initialCap_, cap_) {}
}
