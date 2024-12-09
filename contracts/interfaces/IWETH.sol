// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH.
 * @author PAI3 Team
 * @notice Wrapped ETH token interface.
 */
interface IWETH is IERC20 {
    /**
     * @notice Accepts `ETH` and returns equivalent amount of `Wrapped ETH`.
     * NOTE: `Payable value` must be given.
     */
    function deposit() external payable;

    /**
     * @notice Accepts `Wrapped ETH` and returns equivalent amount of `ETH`.
     * @param wad The amount to withdraw.
     */
    function withdraw(uint256 wad) external;
}
