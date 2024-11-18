// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import { IPAI3 } from "./interfaces/IPAI3.sol";

/**
 * @title PAI3.
 * @author Muhammad Waqas.
 * @notice PAI3 token.
 */
contract PAI3 is Ownable, ERC20, IPAI3 {
    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Assigns initial ownership.
     */
    constructor() Ownable(msg.sender) ERC20("PAI3", "PAI3") {}

    /* ========== FUNCTIONS ========== */

    /**
     * @inheritdoc IPAI3
     */
    function mint(address account, uint256 value) external onlyOwner {
        _mint(account, value);
    }
}
