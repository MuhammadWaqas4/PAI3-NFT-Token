// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IPAI3.
 * @author Muhammad Waqas.
 * @notice PAI3 token interface.
 */
interface IPAI3 is IERC20 {
    /**
     * @notice Creates a `value` amount of tokens and assigns them to `account`,
     * by transferring it from address(0).
     * NOTE: Only `Owner` can call this function.
     * @param account Address of the token recipient.
     * @param value Amount of tokens to mint.
     */
    function mint(address account, uint256 value) external;
}
