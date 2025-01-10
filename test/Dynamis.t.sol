// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { Dynamis } from "contracts/collections/Dynamis.sol";

import { BaseErrors, BaseV2Errors } from "contracts/interfaces/Errors.sol";
import { IBase } from "contracts/interfaces/IBase.sol";

import { PAI3 } from "contracts/tokens/PAI3.sol";

import { _ETH } from "contracts/utils/Globals.sol";

import { MockPriceFeed } from "./externals/MockPriceFeed.sol";
import { MockToken } from "./externals/MockToken.sol";

import { TestHelper } from "./helpers/TestHelper.sol";

/**
 * @title DynamisTest.
 * @author PAI3 Team.
 * @notice Test cases for dynamis.
 */
contract DynamisTest is ERC721Holder, TestHelper {
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 private _USDT;

    string public name;
    string public symbol;
    uint64 public rewardDuration;
    uint256 public rewardPerSecond;
    uint256 public baseCostSingle;
    uint256 public cap;

    IERC20 public pai3;

    AggregatorV3Interface public priceFeedETH;
    AggregatorV3Interface public priceFeedUSDT;

    IERC20[] public tokens;
    AggregatorV3Interface[] public priceFeeds;

    Dynamis public dynamis;

    address public caller;
    uint256 public deadline;
    uint256 public costSingleETH;
    uint256 public costSingleUSDT;

    /* ========== SETUP ========== */

    function setUp() external {
        vm.deal(address(this), totalSupply);
        _USDT = IERC20(new MockToken("Tether USD", "USDT", 6, totalSupply));

        uint256 index = 0;
        uint256 priceETH = 4000 * 1e8;
        uint256 priceUSDT = 1 * 1e8;
        uint256 normalizationETH = 26;
        uint256 normalizationUSDT = 14;

        name = names[index];
        symbol = symbols[index];
        rewardDuration = rewardDurations[index];
        rewardPerSecond = rewardPerSeconds[index];
        baseCostSingle = baseCostSingles[index];
        cap = caps[index];

        pai3 = IERC20(new PAI3(owner, rewardWallet, totalSupply));

        priceFeedETH = AggregatorV3Interface(
            address(new MockPriceFeed(8, 4000 * 1e8))
        );
        priceFeedUSDT = AggregatorV3Interface(
            address(new MockPriceFeed(8, 1 * 1e8))
        );

        tokens = [_ETH, _USDT];
        priceFeeds = [priceFeedETH, priceFeedUSDT];

        dynamis = new Dynamis(
            IBase.BaseParams({
                owner: owner,
                name: name,
                symbol: symbol,
                rewardDuration: rewardDuration,
                rewardPerSecond: rewardPerSecond,
                baseCostSingle: baseCostSingle,
                pai3: pai3,
                treasuryWallet: treasuryWallet,
                rewardWallet: rewardWallet,
                signer: signer,
                baseURI: baseURI,
                tokens: tokens,
                priceFeeds: priceFeeds
            }),
            initialCap,
            cap
        );

        caller = address(this);
        deadline = block.timestamp + 1;
        costSingleETH = (baseCostSingle * 10 ** normalizationETH) / priceETH;
        costSingleUSDT = (baseCostSingle * 10 ** normalizationUSDT) / priceUSDT;
    }

    /* ========== RECEIVE ========== */

    receive() external payable {}

    /* ========== TEST FUNCTIONS ========== */

    function test_MintWithETH() external {
        // Minting single quantity.

        uint256 startTokenId = dynamis.totalSupply() + 1;
        bytes memory signature = _sign(
            caller,
            startTokenId,
            deadline,
            signerPrivateKey
        );

        uint256 quantity = 1;
        uint256 cost = quantity * costSingleETH;

        uint256 callerETH0 = address(this).balance;
        uint256 callerDynamis0 = dynamis.balanceOf(address(this));
        uint256 treasuryETH0 = treasuryWallet.balance;
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        uint256 callerETH1 = address(this).balance;
        uint256 callerDynamis1 = dynamis.balanceOf(address(this));
        uint256 treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - cost, callerETH1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, cost);

        // Minting more than one quantity.

        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = quantity * costSingleETH;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - cost, callerETH1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, cost);

        // Minting single quantity and excess payable cost.

        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 1;
        cost = (quantity * costSingleETH) + 1e18;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - (cost - 1e18), callerETH1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, cost - 1e18);

        // Minting more than one quantity and excess payable cost.

        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = (quantity * costSingleETH) + 1e18;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;
        dynamis.mintWithETH{ value: cost }(quantity, deadline, signature);
        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - (cost - 1e18), callerETH1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, cost - 1e18);
    }

    function test_Mint() external {
        // Minting single quantity.

        uint256 startTokenId = dynamis.totalSupply() + 1;
        bytes memory signature = _sign(
            caller,
            startTokenId,
            deadline,
            signerPrivateKey
        );

        uint256 quantity = 1;
        uint256 cost = quantity * costSingleUSDT;

        _USDT.approve(address(dynamis), cost);

        uint256 callerUSDT0 = _USDT.balanceOf(address(this));
        uint256 callerDynamis0 = dynamis.balanceOf(address(this));
        uint256 treasuryUSDT0 = _USDT.balanceOf(treasuryWallet);
        dynamis.mint(_USDT, quantity, deadline, signature);
        uint256 callerUSDT1 = _USDT.balanceOf(address(this));
        uint256 callerDynamis1 = dynamis.balanceOf(address(this));
        uint256 treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - cost, callerUSDT1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, cost);

        // Minting more than one quantity.

        startTokenId = dynamis.totalSupply() + 1;
        signature = _sign(caller, startTokenId, deadline, signerPrivateKey);

        quantity = 10;
        cost = quantity * costSingleUSDT;

        _USDT.approve(address(dynamis), cost);

        callerUSDT0 = callerUSDT1;
        callerDynamis0 = callerDynamis1;
        treasuryUSDT0 = treasuryUSDT1;
        dynamis.mint(_USDT, quantity, deadline, signature);
        callerUSDT1 = _USDT.balanceOf(address(this));
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - cost, callerUSDT1);
        assertEq(callerDynamis1 - quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, cost);
    }

    function test_Cap() external {
        // Mint params.

        MintParams memory params = MintParams({
            deadline: deadline,
            privateKey: signerPrivateKey,
            quantity: 0,
            costSingle: 0,
            token: IERC20(address(0)),
            caller: caller,
            collection: dynamis,
            errorSelector: 0x0
        });

        // Minting first half of first phase cap with ETH.

        params.quantity = initialCap / 2;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mint(params);

        // // Minting second half of first phase cap with USDT.

        params.quantity = (initialCap / 2) - 1;
        params.costSingle = costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mint(params);

        // Check revert when exceeding cap.

        params.quantity = 2;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = BaseV2Errors.ExceededCap.selector;

        _mint(params);

        params.quantity = initialCap;
        params.costSingle = costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = BaseV2Errors.ExceededCap.selector;

        _mint(params);

        // Minting single quantity to pause first phase.

        params.quantity = 1;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mint(params);

        // Check revert when paused.

        params.quantity = 2;
        params.costSingle = costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mint(params);

        params.quantity = initialCap;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mint(params);

        // Bumping phase with incorrect caller.

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        dynamis.bumpPhase();

        // Bumping phase.

        vm.startPrank(owner);

        dynamis.bumpPhase();

        vm.stopPrank();

        // Minting first half of second phase cap with USDT.

        params.quantity = (cap - initialCap) / 2;
        params.costSingle = costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mint(params);

        // Minting second half of second phase cap with ETH.

        params.quantity = (cap - initialCap) / 2;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mint(params);

        // Minting a few more times to confirm revert on second phase.

        params.quantity = 1;
        params.costSingle = costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = BaseV2Errors.ExceededCap.selector;

        _mint(params);

        params.quantity = cap;
        params.costSingle = costSingleETH;
        params.token = _ETH;
        params.errorSelector = BaseV2Errors.ExceededCap.selector;

        _mint(params);
    }

    function test_Vesting() external {}
}
