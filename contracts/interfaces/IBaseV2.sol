// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBase } from "./IBase.sol";

/**
 * @title IBaseV2.
 * @author PAI3 Team.
 * @notice Base NFT collection version 2.
 */
interface IBaseV2 is IBase {
    /* ========================== TYPES ========================== */

    enum Phase {
        FIRST,
        SECOND
    }

    /* ========================== FUNCTIONS ========================== */

    /**
     * @notice Bumps the `phase` after the first `phase` has ended and changes
     * the state of the contract from `paused` to `unpaused`.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `paused`.
     */
    function bumpPhase() external;

    /**
     * @notice Change the state of the contract from `unpaused` to `paused`.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `unpaused`.
     */
    function pause() external;

    /**
     * @notice Change the state of the contract from `paused` to `unpaused`.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `paused`.
     */
    function unpause() external;

    /**
     * @notice Current phase.
     */
    function phase() external view returns (Phase);

    /**
     * @notice Cap on the `token`'s {totalSupply}.
     */
    function cap() external view returns (uint256);
}
