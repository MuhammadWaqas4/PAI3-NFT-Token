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
    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when `quantity` of `tokens` is minted by `minter`.
     */
    event Mint(
        address indexed minter,
        IERC20 token,
        uint256 fromTokenId,
        uint256 quantity,
        uint256 cost
    );

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints `quantity` of `tokens` and transfers them to the `caller`.
     * NOTE: `Payable value` must be given. Only accepts `ETH` as a payment
     * method.
     * @param quantity Amount of tokens to mint.
     */
    function mintWithETH(uint256 quantity) external payable;

    /**
     * @notice Mints `quantity` of `tokens` and transfers them to the `caller`.
     * NOTE: Only accepts a registered ERC20 `token` as a payment method.
     * @param token ERC20 token to use as a payment method.
     * @param quantity Amount of tokens to mint.
     */
    function mint(IERC20 token, uint256 quantity) external;

    /**
     * @notice Cap on the `token`'s {totalSupply}.
     */
    function cap() external view returns (uint256);
}
