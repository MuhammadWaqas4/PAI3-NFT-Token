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
    /* ========== TYPES ========== */

    enum Phase {
        FIRST,
        SECOND
    }

    /* ========== EVENTS ========== */

    /**
     * @dev Emitted when {signer} is changed to `newSigner` from `oldSigner`.
     */
    event UpdateSigner(address indexed newSigner, address indexed oldSigner);

    /* ========== FUNCTIONS ========== */

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts ETH as a payment method. Can only be called when
     * `unpaused`.
     * @param quantity Amount of tokens to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function mintWithETH(
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external payable;

    /**
     * @notice Mints `quantity` tokens and transfers them to the caller.
     * NOTE: Only accepts registered ERC20 tokens as a payment method. Can only
     * be called when `unpaused`.
     * @param token Token to use as a payment method.
     * @param quantity Amount of tokens to mint.
     * @param deadline Expiration deadline for the signed message.
     * @param signature Signed message to determine correctness.
     */
    function mint(
        IERC20 token,
        uint256 quantity,
        uint256 deadline,
        bytes memory signature
    ) external;

    /**
     * @notice Updates the address of the ECDSA {signer}.
     * NOTE: Only `owner` can call this function.
     * @param newSigner Address of the new data signer.
     */
    function updateSigner(address newSigner) external;

    /**
     * @notice Changes the state of the contract from `paused` to `unpaused`
     * after the first phase has ended and bumps the phase.
     * NOTE: Only `owner` can call this function. Can only be called when
     * `paused`.
     */
    function bumpPhase() external;

    /**
     * @notice Change the state of the contract from unpaused to paused.
     * NOTE: Only `owner` can call this function.
     */
    function pause() external;

    /**
     * @notice Change the state of the contract from paused to unpaused.
     * NOTE: Only `owner` can call this function.
     */
    function unpause() external;

    /**
     * @notice Current phase.
     */
    function phase() external view returns (Phase);

    /**
     * @notice Address of the ECDSA signer.
     */
    function signer() external view returns (address);

    /**
     * @notice Cap on the token's total supply.
     */
    function cap() external view returns (uint256);
}
