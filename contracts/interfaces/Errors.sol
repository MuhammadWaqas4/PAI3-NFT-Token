// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

/**
 * @dev Errors for the {Base} contract.
 */
interface Errors {
    /**
     * @dev Indicates an error during state variable assignment if the argument
     * string is the same as the stored string.
     * @param newString New value of the string.
     * @param oldString Old value of the string.
     */
    error IdenticalStringAssignment(string newString, string oldString);

    /**
     * @dev Indicates an error if a transfer or approval is performed before the
     * vesting deadline.
     */
    error VestingDeadlineNotReached();
}
