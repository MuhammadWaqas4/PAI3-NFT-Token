// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { SafeERC20, IERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { Pausable } from "@openzeppelin/contracts/utils/Pausable.sol";

import { DynamisErrors } from "contracts/interfaces/Errors.sol";
import { IDynamis } from "contracts/interfaces/IDynamis.sol";

import { PAI3 } from "contracts/tokens/PAI3.sol";

import { _ETH } from "contracts/utils/Globals.sol";

import { Dynamis } from "contracts/Dynamis.sol";

import { TestHelper } from "./helpers/TestHelper.sol";

import { MockPriceFeed } from "./mocks/MockPriceFeed.sol";
import { MockToken } from "./mocks/MockToken.sol";

/**
 * @title DynamisTest.
 * @author PAI3 Team.
 * @notice Test cases for dynamis.
 */
contract DynamisTest is ERC721Holder, TestHelper {
    using SafeERC20 for IERC20;

    /* ========================== STATE VARIABLES ========================== */

    IERC20 private _USDT;

    IERC20 public pai3;

    AggregatorV3Interface public priceFeedETH;
    AggregatorV3Interface public priceFeedUSDT;

    IERC20[] public tokens;
    AggregatorV3Interface[] public priceFeeds;

    Dynamis public dynamis;

    uint256 public deadline;
    uint256 public costSingleETH;
    uint256 public costSingleUSDT;

    /* ========================== SETUP ========================== */

    function setUp() external {
        vm.deal(address(this), totalSupply);
        _USDT = IERC20(new MockToken("Tether USD", "USDT", 6, totalSupply));

        uint256 priceETH = 4000 * 1e8;
        uint256 priceUSDT = 1 * 1e8;
        uint256 normalizationETH = 26;
        uint256 normalizationUSDT = 14;

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
            IDynamis.DynamisParams({
                owner: owner,
                name: name,
                symbol: symbol,
                initialCap: initialCap,
                cap: cap,
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
            })
        );

        deadline = block.timestamp + 1;
        costSingleETH = (baseCostSingle * 10 ** normalizationETH) / priceETH;
        costSingleUSDT = (baseCostSingle * 10 ** normalizationUSDT) / priceUSDT;
    }

    /* ========================== RECEIVE ========================== */

    receive() external payable {}

    /* ========================== FUNCTIONS ========================== */

    function test_MintWithETH() external {
        // Mint params.

        MintParams memory params = MintParams({
            deadline: deadline,
            privateKey: signerPrivateKey,
            quantity: 0,
            cost: 0,
            token: IERC20(address(0)),
            caller: address(this),
            collection: dynamis,
            errorSelector: 0x0
        });

        params.token = _ETH;

        // Minting single quantity.

        params.quantity = 1;
        params.cost = params.quantity * costSingleETH;

        uint256 callerETH0 = address(this).balance;
        uint256 callerDynamis0 = dynamis.balanceOf(address(this));
        uint256 treasuryETH0 = treasuryWallet.balance;

        _mintHelper(params);

        uint256 callerETH1 = address(this).balance;
        uint256 callerDynamis1 = dynamis.balanceOf(address(this));
        uint256 treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - params.cost, callerETH1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, params.cost);

        // Minting more than one quantity.

        params.quantity = 10;
        params.cost = params.quantity * costSingleETH;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;

        _mintHelper(params);

        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - params.cost, callerETH1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, params.cost);

        // Minting single quantity and excess payable cost.

        params.quantity = 1;
        params.cost = (params.quantity * costSingleETH) + 1e18;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;

        _mintHelper(params);

        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - (params.cost - 1e18), callerETH1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, params.cost - 1e18);

        // Minting more than one quantity and excess payable cost.

        params.quantity = 10;
        params.cost = (params.quantity * costSingleETH) + 1e18;

        callerETH0 = callerETH1;
        callerDynamis0 = callerDynamis1;
        treasuryETH0 = treasuryETH1;

        _mintHelper(params);

        callerETH1 = address(this).balance;
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryETH1 = treasuryWallet.balance;

        assertEq(callerETH0 - (params.cost - 1e18), callerETH1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryETH1 - treasuryETH0, params.cost - 1e18);
    }

    function test_Mint() external {
        // Mint params.

        MintParams memory params = MintParams({
            deadline: deadline,
            privateKey: signerPrivateKey,
            quantity: 0,
            cost: 0,
            token: IERC20(address(0)),
            caller: address(this),
            collection: dynamis,
            errorSelector: 0x0
        });

        params.token = _USDT;

        // Minting single quantity.

        params.quantity = 1;
        params.cost = params.quantity * costSingleUSDT;

        uint256 callerUSDT0 = _USDT.balanceOf(address(this));
        uint256 callerDynamis0 = dynamis.balanceOf(address(this));
        uint256 treasuryUSDT0 = _USDT.balanceOf(treasuryWallet);

        _mintHelper(params);

        uint256 callerUSDT1 = _USDT.balanceOf(address(this));
        uint256 callerDynamis1 = dynamis.balanceOf(address(this));
        uint256 treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - params.cost, callerUSDT1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, params.cost);

        // Minting more than one quantity.

        params.quantity = 10;
        params.cost = params.quantity * costSingleUSDT;

        callerUSDT0 = callerUSDT1;
        callerDynamis0 = callerDynamis1;
        treasuryUSDT0 = treasuryUSDT1;

        _mintHelper(params);

        callerUSDT1 = _USDT.balanceOf(address(this));
        callerDynamis1 = dynamis.balanceOf(address(this));
        treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - params.cost, callerUSDT1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, params.cost);
    }

    function test_Cap() external {
        // Mint params.

        MintParams memory params = MintParams({
            deadline: deadline,
            privateKey: signerPrivateKey,
            quantity: 0,
            cost: 0,
            token: IERC20(address(0)),
            caller: address(this),
            collection: dynamis,
            errorSelector: 0x0
        });

        // Minting first half of first phase cap with ETH.

        params.quantity = initialCap / 2;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // // Minting second half of first phase cap with USDT.

        params.quantity = (initialCap / 2) - 1;
        params.cost = params.quantity * costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding initial cap.

        params.quantity = 2;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        params.quantity = initialCap;
        params.cost = params.quantity * costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        // Minting single quantity to pause first phase.

        params.quantity = 1;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when paused.

        params.quantity = 2;
        params.cost = params.quantity * costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mintHelper(params);

        params.quantity = initialCap;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mintHelper(params);

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
        params.cost = params.quantity * costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Minting second half of second phase cap with ETH.

        params.quantity = (cap - initialCap) / 2;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding cap.

        params.quantity = 1;
        params.cost = params.quantity * costSingleUSDT;
        params.token = _USDT;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        params.quantity = cap;
        params.cost = params.quantity * costSingleETH;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);
    }

    function test_Vesting() external {
        // Mint params.

        MintParams memory params = MintParams({
            deadline: deadline,
            privateKey: signerPrivateKey,
            quantity: 0,
            cost: 0,
            token: _ETH,
            caller: address(0),
            collection: dynamis,
            errorSelector: 0x0
        });

        // Checking revert with sender when calling with single quantity.

        params.caller = address(this);
        params.quantity = 1;
        params.cost = params.quantity * costSingleETH;

        _mintHelper(params);

        uint256 tokenId = dynamis.totalSupply();

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            address(this),
            secondary,
            tokenId,
            new bytes(0x00)
        );

        // Checking revert with sender when calling with more than one quantity.

        params.quantity = 10;
        params.cost = params.quantity * costSingleETH;

        _mintHelper(params);

        tokenId = dynamis.totalSupply() / 2;

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            address(this),
            secondary,
            tokenId,
            new bytes(0x00)
        );

        // Checking revert with to when calling with single quantity.

        params.caller = secondary;
        params.quantity = 1;
        params.cost = params.quantity * costSingleETH;

        vm.deal(secondary, params.cost);
        vm.startPrank(secondary);

        _mintHelper(params);

        tokenId = dynamis.totalSupply();

        dynamis.approve(tertiary, tokenId);

        vm.startPrank(tertiary);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Checking revert with to when calling with more than one quantity.

        params.quantity = 10;
        params.cost = params.quantity * costSingleETH;

        vm.deal(secondary, params.cost);
        vm.startPrank(secondary);

        _mintHelper(params);

        tokenId = dynamis.totalSupply();

        dynamis.approve(tertiary, tokenId);

        vm.startPrank(tertiary);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Checking revert when calling before vesting expiry time.

        tokenId = dynamis.totalSupply() - params.quantity;
        uint256 startTimestamp = vm.getBlockTimestamp();

        vm.startPrank(secondary);
        vm.warp(startTimestamp + dynamis.VESTING_DURATION() - 1);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Transferring at and after vesting expiry time.

        tokenId = dynamis.totalSupply();

        vm.warp(startTimestamp + dynamis.VESTING_DURATION());

        dynamis.transferFrom(secondary, address(this), tokenId);

        tokenId = dynamis.totalSupply() - 1;

        vm.warp(startTimestamp + dynamis.VESTING_DURATION() + 1);

        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        tokenId = dynamis.totalSupply() - 2;

        vm.warp(startTimestamp + (dynamis.VESTING_DURATION() * 2));

        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Transferring to another address.

        tokenId = dynamis.totalSupply() - params.quantity;

        dynamis.transferFrom(secondary, tertiary, tokenId);
        dynamis.transferFrom(secondary, tertiary, tokenId + 1);
        dynamis.transferFrom(secondary, tertiary, tokenId + 2);

        // Checking revert when calling before vesting expiry time.

        vm.startPrank(tertiary);
        vm.warp(startTimestamp + dynamis.VESTING_DURATION() - 1);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.transferFrom(tertiary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(tertiary, address(this), tokenId + 1);

        vm.expectRevert(DynamisErrors.BeforeVestingExpiry.selector);
        dynamis.safeTransferFrom(
            tertiary,
            address(this),
            tokenId + 2,
            new bytes(0x00)
        );

        // Transferring at and after vesting expiry time.

        vm.warp(startTimestamp + dynamis.VESTING_DURATION());

        dynamis.transferFrom(tertiary, address(this), tokenId);

        vm.warp(startTimestamp + dynamis.VESTING_DURATION() + 1);

        dynamis.safeTransferFrom(tertiary, address(this), tokenId + 1);

        vm.warp(startTimestamp + (dynamis.VESTING_DURATION() * 2));

        dynamis.safeTransferFrom(
            tertiary,
            address(this),
            tokenId + 2,
            new bytes(0x00)
        );

        vm.stopPrank();
    }
}
