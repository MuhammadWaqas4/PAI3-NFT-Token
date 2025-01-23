// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { _ETH } from "contracts/utils/Globals.sol";

import { TestStorage } from "./TestStorage.sol";

abstract contract TestHelper is TestStorage {
    using SafeERC20 for IERC20;
    using MessageHashUtils for bytes32;

    /* ========================== FUNCTIONS ========================== */

    function _mintHelper(MintParams memory params) internal {
        uint256 startTokenId = params.collection.totalSupply() + 1;
        bytes memory signature = _signHelper(
            params.caller,
            startTokenId,
            params.deadline,
            params.privateKey
        );

        if (params.token == _ETH) {
            if (params.errorSelector != 0x0) {
                vm.expectRevert(params.errorSelector);
            }

            params.collection.mintWithETH{ value: params.cost }(
                params.quantity,
                params.deadline,
                signature
            );
        } else {
            params.token.forceApprove(address(params.collection), params.cost);

            if (params.errorSelector != 0x0) {
                vm.expectRevert(params.errorSelector);
            }

            params.collection.mint(
                params.token,
                params.quantity,
                params.deadline,
                signature
            );
        }
    }

    function _signHelper(
        address caller,
        uint256 startTokenId,
        uint256 deadline,
        uint256 privateKey
    ) internal pure returns (bytes memory) {
        bytes32 messageHash = keccak256(
            abi.encodePacked(caller, startTokenId, deadline)
        );

        bytes32 digest = messageHash.toEthSignedMessageHash();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        bytes memory signature = abi.encodePacked(r, s, v);

        return signature;
    }
}
