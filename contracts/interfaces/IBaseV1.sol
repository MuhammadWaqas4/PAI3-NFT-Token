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
    /**
     * @notice Cap on the `token`'s {totalSupply}.
     */
    function cap() external view returns (uint256);
}
