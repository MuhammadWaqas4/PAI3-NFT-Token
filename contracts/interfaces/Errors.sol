// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/**
 * @dev Errors for the {Base} contract.
 */
interface Errors {
    /**
     * @dev Indicates that a given address is not valid. For example,
     * `address(0)`.
     */
    error InvalidAddress();

    /**
     * @dev Indicates that a given integer value is not valid. For example, `0`.
     */
    error InvalidValue();

    /**
     * @dev Indicates that a given string is not valid. For example, `""`.
     */
    error InvalidString();

    /**
     * @dev Indicates an error if the number of arguments do not match.
     */
    error ArgumentArityMismatch();

    /**
     * @dev Indicates that a payable value is not valid. For example, `0`.
     */
    error InvalidPayableValue();

    /**
     * @dev Indicates that a given payment token is not valid. For example,
     * `address(0)`.
     */
    error InvalidPaymentToken();

    /**
     * @dev Indicates that a given quantity is not valid. For example, `0`.
     */
    error InvalidQuantity();

    /**
     * @dev Indicates that a calculated cost is not valid. For example, `0`.
     */
    error InvalidCost();

    /**
     * @dev Indicates an error if a given token is not a registered payment
     * token.
     */
    error PaymentTokenNotRegistered();

    /**
     * @dev Indicates an error if the total supply cap has been exceeded.
     */
    error ExceededCap();

    /**
     * @dev Indicates an error if a transfer or approval is performed before the
     * vesting deadline.
     */
    error VestingDeadlineNotReached();

    /**
     * @dev Indicates an error during state variable assignment if the
     * replacement string is the same as the stored string.
     */
    error IdenticalStringAssignment();
}
