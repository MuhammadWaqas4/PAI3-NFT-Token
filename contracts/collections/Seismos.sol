// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { BaseSimple } from "../bases/BaseSimple.sol";

/**
 * @title Seismos.
 * @author PAI3 Team.
 * @notice Seismos NFT collection.
 */
contract Seismos is BaseSimple {
    /* ========== CONSTRUCTOR ========== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param owner_ Address of the contract owner.
     * @param baseURI_ Base URI for computing the tokenURI.
     */
    constructor(
        address owner_,
        string memory baseURI_
    ) BaseSimple(owner_, "Seismos", "SES", baseURI_) {}
}
