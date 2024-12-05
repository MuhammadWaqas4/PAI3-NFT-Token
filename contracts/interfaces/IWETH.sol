// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title IWETH.
 * @notice WETH token interface.
 */
interface IWETH is IERC20 {
    /**
     * @dev Accepts ETH and returns equivalent amount of Wrapped ETH.
     */
    function deposit() external payable;

    /**
     * @dev Accepts Wrapped ETH and returns equivalent amount of ETH.
     */
    function withdraw(uint256 wad) external;
}
