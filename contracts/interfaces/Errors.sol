// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/**
 * @dev Errors for the Dynamis contract.
 */
interface DynamisErrors {
    /**
     * @dev Indicates a failure with the caller if the caller is not the owner
     * of a tokenId.
     */
    error CallerNotOwner();

    /**
     * @dev Indicates a failure with the total supply if the total supply
     * exceeds the cap.
     */
    error ExceededCap();

    /**
     * @dev Indicates a failure with the launch if the launch has ended.
     */
    error LaunchEnded();

    /**
     * @dev Indicates a failure with the launch if the launch has not yet
     * started.
     */
    error LaunchNotStarted();

    /**
     * @dev Indicates a failure with the launch if the launch is in between
     * phases and hence is on hold.
     */
    error LaunchOnHold();

    /**
     * @dev Indicates a failure with the token if the token is not registered as
     * a payment token with a cooresponding price feed.
     */
    error IncorrectPaymentToken();

    /**
     * @dev Indicates a failure with the signature if the signature recovers a
     * different address than the signer.
     */
    error IncorrectSignatureRecovery();

    /**
     * @dev Indicates a failure with the cost if the cost calculated is less
     * than the base cost for a single token.
     */
    error InsufficientCost();

    /**
     * @dev Indicates a failure with the reward if the reward is `0`.
     */
    error InsufficientReward();

    /**
     * @dev Indicates a failure with the quantity if the quantity of tokens
     * being minted in the sale phase is less than the minimum sale mint
     * quantity.
     */
    error InsufficientSaleMintQuantity();

    /**
     * @dev Indicates an error with the given argument address. For example,
     * `address(0)`.
     */
    error InvalidAddress();

    /**
     * @dev Indicates an error with the given argument amount. For example, `0`.
     */
    error InvalidAmount();

    /**
     * @dev Indicates an error with the given argument array's arity. For
     * example, `firstArray.length() != secondArray.length()`.
     */
    error InvalidArrayArity();

    /**
     * @dev Indicates an error with the given argument array's length. For
     * example, `array.length() == 0`.
     */
    error InvalidArrayLength();

    /**
     * @dev Indicates an error with the given argument's assignment. For
     * example, `argument == stateVariable`.
     */
    error InvalidAssignment();

    /**
     * @dev Indicates an error with the given argument payable value. For
     * example, `0`.
     */
    error InvalidPayableValue();

    /**
     * @dev Indicates an error with the given argument string. For example,
     * `""`.
     */
    error InvalidString();

    /**
     * @dev Indicates a failure with the deadline if the deadline has been
     * crossed when a signature is verified.
     */
    error SignatureDeadlineCrossed();

    /**
     * @dev Indicates a failure with the signature if the signature has already
     * been seen at least once.
     */
    error SignatureAlreadySeen();

    /**
     * @dev Indicates a failure with the expiry if the expiry has not been
     * crossed when a transfer or approval is performed.
     */
    error Vested();
}
