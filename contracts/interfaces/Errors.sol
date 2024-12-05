// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/**
 * @dev Errors for the Base contract.
 */
interface BaseErrors {
    /**
     * @dev Indicates an error with the given argument `address`. For example,
     * `address(0)`.
     */
    error InvalidAddress();

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
     * @dev Indicates an error with the given argument `string`. For example,
     * `""`.
     */
    error InvalidString();

    /**
     * @dev Indicates an error with the given argument `value`. For example,
     * `0`.
     */
    error InvalidValue();

    /**
     * @dev Indicates a failure with the `block timestamp` if the `block
     * timestamp` when a `transfer` or `approval` is performed subceeds the
     * `vesting deadline`.
     */
    error SubceededVestingDeadline();
}

/**
 * @dev Errors for the BaseSimple contract.
 */
interface BaseSimpleErrors {
    /**
     * @dev Indicates a failure with the `minter` if the `minter` already has a
     * `balance` of `1`.
     */
    error AlreadyOwned();

    /**
     * @dev Indicates an error with the given argument's assignment. For
     * example, `argument == stateVariable`.
     */
    error InvalidAssignment();

    /**
     * @dev Indicates an error with the given argument `string`. For example,
     * `""`.
     */
    error InvalidString();
}

/**
 * @dev Errors for the BaseV1 contract.
 */
interface BaseV1Errors {
    /**
     * @dev Indicates a failure with the `total supply` if the `total supply`
     * exceeds the `cap`.
     */
    error ExceededCap();

    /**
     * @dev Indicates a failure with the `token` if the `token` is not
     * registered as a payment token with a cooresponding `price feed`.
     */
    error IncorrectPaymentToken();

    /**
     * @dev Indicates a failure with the `cost` calculated if the `cost` is
     * below the `base cost single`.
     */
    error InsufficientCost();

    /**
     * @dev Indicates an error with the given argument `payable value`. For
     * example, `0`.
     */
    error InvalidPayableValue();
}

/**
 * @dev Errors for the BaseV2 contract.
 */
interface BaseV2Errors {
    /**
     * @dev Indicates a failure with the `phase` if the `phase` has already been
     * bumped.
     */
    error AlreadyBumpedPhase();

    /**
     * @dev Indicates a failure with the `total supply` if the `total supply`
     * exceeds the `cap`.
     */
    error ExceededCap();

    /**
     * @dev Indicates a failure with the `token` if the `token` is not
     * registered as a payment token with a cooresponding `price feed`.
     */
    error IncorrectPaymentToken();

    /**
     * @dev Indicates a failure with the `signature` if the `signature` recovers
     * a different address than the signer.
     */
    error IncorrectSignatureRecovery();

    /**
     * @dev Indicates a failure with the `cost` calculated if the `cost` is
     * below the `base cost single`.
     */
    error InsufficientCost();

    /**
     * @dev Indicates an error with the given argument `payable value`. For
     * example, `0`.
     */
    error InvalidPayableValue();
}

/**
 * @dev Errors for the Marketplace contract.
 */
interface MarketplaceErrors {
    /**
     * @dev Indicates a failure with the `tokenId` if the `tokenId` is already
     * on `sale` for the corresponding `collection`.
     */
    error AlreadyOnSale();

    /**
     * @dev Indicates a failure with the `token` if the `token` is not
     * registered as a payment token with a cooresponding `price feed`.
     */
    error IncorrectPaymentToken();

    // error IncorrectBidder();
    // error IncorrectCollection();
    // error IncorrectSale();
    // error IncorrectTokenIdOwner();
    // error InsufficientBid();
    // error InsufficientTokenApproval();
    // error InsufficientTokenIdApproval();
    // error InsufficientTokenBalance();

    /**
     * @dev Indicates an error with the given argument `address`. For example,
     * `address(0)`.
     */
    error InvalidAddress();

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
     * @dev Indicates an error with the given argument `payable value`. For
     * example, `0`.
     */
    error InvalidPayableValue();

    /**
     * @dev Indicates an error with the given argument `value`. For example,
     * `0`.
     */
    error InvalidValue();
}

// TODO multicall or maybe dont use it since he can wrap more eth if he needs to
// error PreExistingWrappedBalance();
