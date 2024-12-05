// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { IBase } from "./IBase.sol";

/**
 * @title IBaseV1.
 * @author PAI3 Team.
 * @notice Base NFT collection version 1.
 */
interface IBaseV1 is IBase {
    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts ETH as a payment method. Can only be called when
     * `unpaused`.
     * @param quantity Amount of tokens to mint.
     */
    function mintWithETH(uint256 quantity) external payable;

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts registered ERC20 tokens as a payment method. Can only
     * be called when `unpaused`.
     * @param token Token to use as a payment method.
     * @param quantity Amount of tokens to mint.
     */
    function mint(IERC20 token, uint256 quantity) external;

    /**
     * @notice Cap on the token's total supply.
     */
    function cap() external view returns (uint256);
}
