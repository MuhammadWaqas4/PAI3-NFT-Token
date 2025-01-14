// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import { BaseAlt } from "../bases/BaseAlt.sol";

/**
 * @title Seismos.
 * @author PAI3 Team.
 * @notice Seismos NFT collection.
 */
contract Seismos is BaseAlt {
    /* ========================== CONSTRUCTOR ========================== */

    /**
     * @dev Constructor. Initializes parent contract.
     * @param paramsAlt_ Params necessary for contract deployment.
     */
    constructor(BaseAltParams memory paramsAlt_) BaseAlt(paramsAlt_) {}
}
