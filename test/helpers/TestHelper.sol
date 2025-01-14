// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

import { IBase } from "contracts/interfaces/IBase.sol";

import { _ETH } from "contracts/utils/Globals.sol";

contract TestHelper is Test {
    using SafeERC20 for IERC20;
    using MessageHashUtils for bytes32;

    /* ========================== STATE VARIABLES ========================== */

    address public secondary;
    address public tertiary;

    uint256 public signerPrivateKey;
    uint256 public secondarySignerPrivateKey;

    uint256 public totalSupply;
    uint256 public initialCap;

    string[] public names;
    string[] public symbols;
    uint256[] public rewardPerSeconds;
    uint256[] public baseCostSingles;
    uint256[] public caps;

    uint64[] public rewardDurations;

    address public owner;
    address public treasuryWallet;
    address public rewardWallet;
    address public signer;
    address public secondarySigner;
    string public baseURI;

    /* ========================== TYPES ========================== */

    struct MintParams {
        uint256 deadline;
        uint256 privateKey;
        uint256 quantity;
        uint256 cost;
        address caller;
        IERC20 token;
        IBase collection;
        bytes4 errorSelector;
    }

    /* ========================== CONSTRUCTOR ========================== */

    constructor() {
        secondary = address(0xAAA);
        tertiary = address(0xBBB);

        signerPrivateKey = 100;
        secondarySignerPrivateKey = 200;

        totalSupply = vm.envUint("TOTAL_SUPPLY");
        initialCap = vm.envUint("INITIAL_CAP");

        names = vm.envString("NAMES", "|");
        symbols = vm.envString("SYMBOLS", "|");
        rewardPerSeconds = vm.envUint("REWARD_PER_SECONDS", "|");
        baseCostSingles = vm.envUint("BASE_COST_SINGLES", "|");
        caps = vm.envUint("CAPS", "|");

        uint256[] memory tempRewardDurations = vm.envUint(
            "REWARD_DURATIONS",
            "|"
        );

        for (uint256 i = 0; i < tempRewardDurations.length; i++) {
            rewardDurations.push(uint64(tempRewardDurations[i]));
        }

        owner = address(0xCCC);
        treasuryWallet = address(0xDDD);
        rewardWallet = address(0xEEE);
        signer = vm.addr(signerPrivateKey);
        secondarySigner = vm.addr(secondarySignerPrivateKey);
        baseURI = "ipfs://";

        vm.label(secondary, "secondary");
        vm.label(tertiary, "tertiary");
        vm.label(owner, "owner");
        vm.label(treasuryWallet, "treasuryWallet");
        vm.label(rewardWallet, "rewardWallet");
        vm.label(signer, "signer");
        vm.label(secondarySigner, "secondarySigner");
    }

    /* ========================== FUNCTIONS ========================== */

    function _mint(MintParams memory params) internal {
        uint256 startTokenId = params.collection.totalSupply() + 1;
        bytes memory signature = _sign(
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
            params.token.approve(address(params.collection), params.cost);

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

    function _sign(
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
