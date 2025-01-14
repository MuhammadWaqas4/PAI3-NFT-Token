// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { BaseV1 } from "../bases/BaseV1.sol";

/**
 * @title Ethos.
 * @author PAI3 Team.
 * @notice Ethos NFT collection.
 */
contract Ethos is BaseV1 {
    /* ========================== CONSTRUCTOR ========================== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param params_ Params necessary for contract deployment.
     * @param cap_ Cap on the number of minted tokens.
     */
    constructor(
        BaseParams memory params_,
        uint256 cap_
    ) BaseV1(params_, cap_) {}
}
