// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import { LinkedListStorage } from "../interfaces/LinkedListStorage.sol";

/**
 * @title LinkedListLogic.
 * @author PAI3 Team.
 * @notice Linked list implementation logic library.
 */
library LinkedListLogic {
    /* ========== SETUP ========== */

    /**
     * @dev Setup for {List} object. NOTE: Must be called either during contract
     * creation or initialization.
     * NOTE: {headIndex} is `((2 ** 256) / 2) - 1` by default and will not
     * change during runtime. {head}'s {nextIndex} will always stay the default
     * value, i.e. 0, since there will be no node that proceeds {head}.
     * NOTE: {tailIndex} is `0` by default and will not change during runtime.
     * {tail}'s {prevIndex} will always stay the default value, i.e. 0, since
     * there will be no node that preceeds {tail}.
     */
    function setup(LinkedListStorage.LinkedList storage linkedList) internal {
        int headIndex = type(int256).max;
        int tailIndex = -1;

        linkedList.headIndex = headIndex;
        linkedList.tailIndex = tailIndex;

        // linkedList.nodes[headIndex].nextIndex = 0;
        linkedList.nodes[headIndex].prevIndex = tailIndex;
        linkedList.nodes[tailIndex].nextIndex = headIndex;
        // linkedList.nodes[tailIndex].prevIndex = 0;

        // linkedList.count = 0;
    }

    /* ========== FUNCTIONS ========== */

    /**
     * @dev All new nodes will be added at the `highestIndex` and any crucial
     * checks must be performed before calling this function.
     */
    function insert(
        LinkedListStorage.LinkedList storage linkedList,
        LinkedListStorage.Bid memory bid
    ) internal returns (int256) {
        int256 headIndex = linkedList.headIndex;
        LinkedListStorage.Node storage head = linkedList.nodes[headIndex];
        int256 highestIndex = head.prevIndex;
        LinkedListStorage.Node storage highest = linkedList.nodes[highestIndex];

        int256 index = linkedList.count;
        LinkedListStorage.Node storage data = linkedList.nodes[index];

        data.nextIndex = headIndex;
        data.prevIndex = highestIndex;
        data.data = bid;

        head.prevIndex = index;
        highest.nextIndex = index;

        linkedList.count++;
        return index;
    }

    /**
     * @dev Will remove any specified node and any crucial checks must be
     * performed before calling this function.
     * NOTE: Checks to make sure that the {head} and {tail} are not the ones
     * being removed must always be performed externally.
     */
    function remove(
        LinkedListStorage.LinkedList storage linkedList,
        int256 bidIndex
    ) internal {
        LinkedListStorage.Node memory toRemove = linkedList.nodes[bidIndex];
        delete linkedList.nodes[bidIndex];

        LinkedListStorage.Node storage next = linkedList.nodes[
            toRemove.nextIndex
        ];
        LinkedListStorage.Node storage prev = linkedList.nodes[
            toRemove.prevIndex
        ];

        next.prevIndex = toRemove.prevIndex;
        prev.nextIndex = toRemove.nextIndex;
    }

    /**
     * @dev Returns the {data} in the {Node} that immediately preceeds {head}.
     */
    function getHighestData(
        LinkedListStorage.LinkedList storage linkedList
    )
        internal
        view
        returns (int256 highestIndex, LinkedListStorage.Bid memory highestData)
    {
        highestIndex = linkedList.nodes[linkedList.headIndex].prevIndex;
        highestData = linkedList.nodes[highestIndex].data;
    }

    /**
     * @dev Returns the {data} in the {Node} at `index`.
     */
    function getData(
        LinkedListStorage.LinkedList storage linkedList,
        int256 index
    ) internal view returns (LinkedListStorage.Bid memory) {
        return linkedList.nodes[index].data;
    }

    /**
     * @dev Returns the `amount` in the {Node} that immediately preceeds {head}.
     */
    function getHighestAmount(
        LinkedListStorage.LinkedList storage linkedList
    ) internal view returns (uint256) {
        return
            linkedList
                .nodes[linkedList.nodes[linkedList.headIndex].prevIndex]
                .data
                .amountToken;
    }

    /**
     * @dev Returns the `amount` in the {Node} at `index`.
     */
    function getAmount(
        LinkedListStorage.LinkedList storage linkedList,
        int256 index
    ) internal view returns (uint256) {
        return linkedList.nodes[index].data.amountToken;
    }

    /**
     * @dev Returns whether the {Node} in `bidIndex` contains data or not.
     */
    function exists(
        LinkedListStorage.LinkedList storage linkedList,
        int256 bidIndex
    ) internal view returns (bool) {
        return linkedList.nodes[bidIndex].data.bidder != address(0);
    }
}
