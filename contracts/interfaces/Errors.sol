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
     * @dev Indicates that a given token is not valid. For example,
     * `address(0)`.
     */
    error InvalidToken();

    /**
     * @dev Indicates that a given quantity is not valid. For example, `0`.
     */
    error InvalidQuantity();

    /**
     * @dev Indicates that a price feed for a given token is not valid. For
     * example, `address(0)`.
     */
    error InvalidPriceFeed();

    /**
     * @dev Indicates that a calculated cost is not valid. For example, `0`.
     */
    error InvalidCost();

    /**
     * @dev Total supply cap has been exceeded.
     */
    error ExceededCap(uint256 increasedSupply, uint256 cap);

    /**
     * @dev Indicates an error if a transfer or approval is performed before the
     * vesting deadline.
     */
    error VestingDeadlineNotReached();

    /**
     * @dev Indicates an error during state variable assignment if the argument
     * string is the same as the stored string.
     * @param newString New value of the string.
     * @param oldString Old value of the string.
     */
    error IdenticalStringAssignment(string newString, string oldString);
}
