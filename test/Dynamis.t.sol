// SPDX-License-Identifier: MIT

pragma solidity 0.8.28;

import "forge-std/Test.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
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

    AggregatorV3Interface public priceFeedEth;
    AggregatorV3Interface public priceFeedUSDT;

    IERC20[] public tokens;
    AggregatorV3Interface[] public priceFeeds;

    Dynamis public dynamis;

    /* ========================== SETUP ========================== */

    function setUp() external {
        vm.deal(address(this), totalSupply);
        _USDT = IERC20(new MockToken("Tether USD", "USDT", 6, totalSupply));

        pai3 = IERC20(new PAI3(owner, rewardWallet, totalSupply));

        priceFeedEth = AggregatorV3Interface(
            address(new MockPriceFeed(8, 4000 * 1e8))
        );
        priceFeedUSDT = AggregatorV3Interface(
            address(new MockPriceFeed(8, 1 * 1e8))
        );

        tokens = [_ETH, _USDT];
        priceFeeds = [priceFeedEth, priceFeedUSDT];

        dynamis = new Dynamis(
            IDynamis.DynamisParams({
                owner: owner,
                name: name,
                symbol: symbol,
                cap: cap,
                pai3: pai3,
                treasuryWallet: treasuryWallet,
                rewardWallet: rewardWallet,
                signer: signer,
                baseURI: baseURI,
                situationalCaps: situationalCaps,
                saleBaseCosts: saleBaseCosts,
                phaseBaseCosts: phaseBaseCosts,
                windows: windows,
                tokens: tokens,
                priceFeeds: priceFeeds
            })
        );

        vm.startPrank(rewardWallet);

        pai3.approve(address(dynamis), type(uint256).max);

        vm.stopPrank();
    }

    /* ========================== RECEIVE ========================== */

    receive() external payable {}

    /* ========================== FUNCTIONS ========================== */

    function test_MintSaleWithEth() external {
        // Mint params.

        MintSaleParams memory params = MintSaleParams({
            sale: IDynamis.Sale(0),
            saleIndex: 0,
            quantity: 0,
            deadline: 0,
            privateKey: signerPrivateKey,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        uint8 typeIndex = uint8(Type.NODE);

        params.sale = IDynamis.Sale.NODE;
        params.saleIndex = uint8(IDynamis.Sale.NODE);
        params.costSingle = costSingleEth[typeIndex];
        params.token = _ETH;

        // Minting.

        params.quantity = 200;
        params.deadline++;
        params.cost = params.quantity * params.costSingle;

        uint256 callerEth0 = params.caller.balance;
        uint256 callerDynamis0 = dynamis.balanceOf(params.caller);
        uint256 treasuryEth0 = treasuryWallet.balance;

        _mintSaleHelper(params);

        uint256 callerEth1 = params.caller.balance;
        uint256 callerDynamis1 = dynamis.balanceOf(params.caller);
        uint256 treasuryEth1 = treasuryWallet.balance;

        assertEq(callerEth0 - params.cost, callerEth1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryEth1 - treasuryEth0, params.cost);

        // Minting.

        params.quantity = 400;
        params.deadline++;
        params.cost = params.quantity * params.costSingle;

        callerEth0 = callerEth1;
        callerDynamis0 = callerDynamis1;
        treasuryEth0 = treasuryEth1;

        _mintSaleHelper(params);

        callerEth1 = params.caller.balance;
        callerDynamis1 = dynamis.balanceOf(params.caller);
        treasuryEth1 = treasuryWallet.balance;

        assertEq(callerEth0 - params.cost, callerEth1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryEth1 - treasuryEth0, params.cost);

        // Minting.

        params.quantity = 200;
        params.deadline++;
        params.cost = (params.quantity * params.costSingle) + 1e18;

        callerEth0 = callerEth1;
        callerDynamis0 = callerDynamis1;
        treasuryEth0 = treasuryEth1;

        _mintSaleHelper(params);

        callerEth1 = params.caller.balance;
        callerDynamis1 = dynamis.balanceOf(params.caller);
        treasuryEth1 = treasuryWallet.balance;

        assertEq(callerEth0 - (params.cost - 1e18), callerEth1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryEth1 - treasuryEth0, params.cost - 1e18);

        // Minting.

        params.quantity = 600;
        params.deadline++;
        params.cost = (params.quantity * params.costSingle) + 1e18;

        callerEth0 = callerEth1;
        callerDynamis0 = callerDynamis1;
        treasuryEth0 = treasuryEth1;

        _mintSaleHelper(params);

        callerEth1 = params.caller.balance;
        callerDynamis1 = dynamis.balanceOf(params.caller);
        treasuryEth1 = treasuryWallet.balance;

        assertEq(callerEth0 - (params.cost - 1e18), callerEth1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryEth1 - treasuryEth0, params.cost - 1e18);

        // Revert on insufficient quantity.

        params.quantity = 0;
        params.deadline++;
        params.errorSelector = DynamisErrors.InsufficientQuantity.selector;

        _mintSaleHelper(params);
    }

    function test_MintSale() external {
        // Mint params.

        MintSaleParams memory params = MintSaleParams({
            sale: IDynamis.Sale(0),
            saleIndex: 0,
            quantity: 0,
            deadline: 0,
            privateKey: signerPrivateKey,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        uint8 typeIndex = uint8(Type.NODE);

        params.sale = IDynamis.Sale.NODE;
        params.saleIndex = uint8(IDynamis.Sale.NODE);
        params.costSingle = costSingleUSDT[typeIndex];
        params.token = _USDT;

        // Minting.

        params.quantity = 200;
        params.deadline++;
        params.cost = params.quantity * params.costSingle;

        uint256 callerUSDT0 = _USDT.balanceOf(params.caller);
        uint256 callerDynamis0 = dynamis.balanceOf(params.caller);
        uint256 treasuryUSDT0 = _USDT.balanceOf(treasuryWallet);

        _mintSaleHelper(params);

        uint256 callerUSDT1 = _USDT.balanceOf(params.caller);
        uint256 callerDynamis1 = dynamis.balanceOf(params.caller);
        uint256 treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - params.cost, callerUSDT1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, params.cost);

        // Minting.

        params.quantity = 800;
        params.deadline++;
        params.cost = params.quantity * params.costSingle;

        callerUSDT0 = callerUSDT1;
        callerDynamis0 = callerDynamis1;
        treasuryUSDT0 = treasuryUSDT1;

        _mintSaleHelper(params);

        callerUSDT1 = _USDT.balanceOf(params.caller);
        callerDynamis1 = dynamis.balanceOf(params.caller);
        treasuryUSDT1 = _USDT.balanceOf(treasuryWallet);

        assertEq(callerUSDT0 - params.cost, callerUSDT1);
        assertEq(callerDynamis1 - params.quantity, callerDynamis0);
        assertEq(treasuryUSDT1 - treasuryUSDT0, params.cost);

        // Revert on insufficient quantity.

        params.quantity = 0;
        params.deadline++;
        params.errorSelector = DynamisErrors.InsufficientQuantity.selector;

        _mintSaleHelper(params);
    }

    function test_Cap() external {
        // Mint params.

        MintParams memory params = MintParams({
            quantity: 0,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        // Getting first phase cap.

        uint256 firstPhaseCap = situationalCaps[
            uint8(IDynamis.Scenario.FIRST_PHASE)
        ];

        // Moving to first phase.

        IDynamis.Window[] memory testWindows = new IDynamis.Window[](7);

        uint8 phaseIndex = uint8(IDynamis.Phase.FIRST);
        uint8 typeIndex = uint8(Type.FIRST);
        testWindows[typeIndex] = windows[typeIndex];
        vm.warp(testWindows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = firstPhaseCap;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Setting next phase window with incorrect caller.

        phaseIndex++;
        typeIndex++;
        testWindows[typeIndex] = IDynamis.Window({
            startTimestamp: testWindows[typeIndex - 1].endTimestamp,
            endTimestamp: testWindows[typeIndex - 1].endTimestamp + 3 days
        });

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        dynamis.setPhaseWindow(
            IDynamis.Phase(phaseIndex),
            testWindows[typeIndex]
        );

        // Setting next phase window.

        vm.startPrank(owner);

        dynamis.setPhaseWindow(
            IDynamis.Phase(phaseIndex),
            testWindows[typeIndex]
        );

        vm.stopPrank();

        // Moving to next phase.

        vm.warp(testWindows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding cap.

        params.quantity = cap - dynamis.totalSupply() + 1;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        // Setting next phase window.

        phaseIndex++;
        typeIndex++;
        testWindows[typeIndex] = IDynamis.Window({
            startTimestamp: testWindows[typeIndex - 1].endTimestamp,
            endTimestamp: testWindows[typeIndex - 1].endTimestamp + 3 days
        });

        vm.startPrank(owner);

        dynamis.setPhaseWindow(
            IDynamis.Phase(phaseIndex),
            testWindows[typeIndex]
        );

        vm.stopPrank();

        // Moving to next phase.

        vm.warp(testWindows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding cap.

        params.quantity = cap - dynamis.totalSupply() + 1;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        // Setting next phase window.

        phaseIndex++;
        typeIndex++;
        testWindows[typeIndex] = IDynamis.Window({
            startTimestamp: testWindows[typeIndex - 1].endTimestamp,
            endTimestamp: testWindows[typeIndex - 1].endTimestamp + 3 days
        });

        vm.startPrank(owner);

        dynamis.setPhaseWindow(
            IDynamis.Phase(phaseIndex),
            testWindows[typeIndex]
        );

        vm.stopPrank();

        // Moving to next phase.

        vm.warp(testWindows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding cap.

        params.quantity = cap - dynamis.totalSupply() + 1;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        // Setting next phase window.

        phaseIndex++;
        typeIndex++;
        testWindows[typeIndex] = IDynamis.Window({
            startTimestamp: testWindows[typeIndex - 1].endTimestamp,
            endTimestamp: testWindows[typeIndex - 1].endTimestamp + 3 days
        });

        vm.startPrank(owner);

        dynamis.setPhaseWindow(
            IDynamis.Phase(phaseIndex),
            testWindows[typeIndex]
        );

        vm.stopPrank();

        // Moving to next phase.

        vm.warp(testWindows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding cap.

        params.quantity = cap - dynamis.totalSupply() + 1;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);
    }

    function test_SituationalCaps() external {
        // Mint params.

        MintParams memory params = MintParams({
            quantity: 0,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        // Getting reserved cap.

        uint256 reservedCap = situationalCaps[
            uint8(IDynamis.Scenario.RESERVED)
        ];

        // Minting.

        vm.startPrank(owner);

        uint256 quantity = reservedCap / 2;

        dynamis.safeMint(owner, quantity);

        // Minting.

        quantity = reservedCap % 2 == 0
            ? (reservedCap / 2) - 1
            : reservedCap / 2;

        dynamis.safeMint(owner, quantity);

        // Checking revert when exceeding initial cap.

        quantity = 2;

        vm.expectRevert(DynamisErrors.ExceededCap.selector);
        dynamis.safeMint(owner, quantity);

        quantity = reservedCap;

        vm.expectRevert(DynamisErrors.ExceededCap.selector);
        dynamis.safeMint(owner, quantity);

        // Minting.

        quantity = 1;

        dynamis.safeMint(owner, quantity);

        vm.stopPrank();

        // Getting first phase cap.

        uint256 firstPhaseCap = situationalCaps[
            uint8(IDynamis.Scenario.FIRST_PHASE)
        ];

        // Moving to first phase.

        uint8 typeIndex = uint8(Type.FIRST);
        vm.warp(windows[typeIndex].startTimestamp + 1);

        // Minting.

        params.quantity = firstPhaseCap / 2;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Minting.

        params.quantity = firstPhaseCap % 2 == 0
            ? (firstPhaseCap / 2) - 1
            : firstPhaseCap / 2;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // Checking revert when exceeding initial cap.

        params.quantity = 2;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        params.quantity = firstPhaseCap;
        params.costSingle = costSingleUSDT[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = DynamisErrors.ExceededCap.selector;

        _mintHelper(params);

        // Minting.

        params.quantity = 1;
        params.costSingle = costSingleEth[typeIndex];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);

        // // Setting next phase window with incorrect caller.

        // uint128 secondPhaseStartTimestamp = windows[uint8(Type.FIRST)]
        //     .endTimestamp;
        // uint128 secondPhaseEndTimestamp = secondPhaseStartTimestamp + 3 days;

        // vm.expectRevert(
        //     abi.encodeWithSelector(
        //         Ownable.OwnableUnauthorizedAccount.selector,
        //         address(this)
        //     )
        // );
        // dynamis.setPhaseWindow(
        //     IDynamis.Phase.SECOND,
        //     IDynamis.Window({
        //         startTimestamp: secondPhaseStartTimestamp,
        //         endTimestamp: secondPhaseEndTimestamp
        //     })
        // );

        // // Setting next phase window.

        // vm.startPrank(owner);

        // dynamis.setPhaseWindow(
        //     IDynamis.Phase.SECOND,
        //     IDynamis.Window(secondPhaseStartTimestamp, secondPhaseEndTimestamp)
        // );

        // vm.stopPrank();

        // // Moving to next phase.

        // typeIndex = uint8(Type.SECOND);
        // vm.warp(secondPhaseStartTimestamp + 1);

        // // Minting.

        // params.quantity = (cap - firstPhaseCap) / 2;
        // params.costSingle = costSingleUSDT[typeIndex];
        // params.cost = params.quantity * params.costSingle;
        // params.token = _USDT;
        // params.errorSelector = 0x0;

        // _mintHelper(params);

        // // Minting.

        // params.quantity = (cap - firstPhaseCap) / 2;
        // params.costSingle = costSingleEth[typeIndex];
        // params.cost = params.quantity * params.costSingle;
        // params.token = _ETH;
        // params.errorSelector = 0x0;

        // _mintHelper(params);

        // // Checking revert when exceeding cap.

        // params.quantity = 1;
        // params.costSingle = costSingleUSDT[typeIndex];
        // params.cost = params.quantity * params.costSingle;
        // params.token = _USDT;
        // params.errorSelector = DynamisErrors.ExceededCap.selector;

        // _mintHelper(params);

        // params.quantity = cap;
        // params.costSingle = costSingleEth[typeIndex];
        // params.cost = params.quantity * params.costSingle;
        // params.token = _ETH;
        // params.errorSelector = DynamisErrors.ExceededCap.selector;

        // _mintHelper(params);
    }

    function test_Pause() external {
        // Mint params.

        MintParams memory params = MintParams({
            quantity: 0,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        uint8 typeIndex = uint8(Type.FIRST);
        vm.warp(windows[typeIndex].startTimestamp + 1);

        // Pausing with incorrect caller.

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        dynamis.pause();

        // Pausing.

        vm.startPrank(owner);

        dynamis.pause();

        vm.stopPrank();

        // Checking revert when paused.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[uint8(Type.FIRST)];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mintHelper(params);

        params.quantity = 100;
        params.costSingle = costSingleEth[uint8(Type.FIRST)];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = Pausable.EnforcedPause.selector;

        _mintHelper(params);

        // Unpausing with incorrect caller.

        vm.expectRevert(
            abi.encodeWithSelector(
                Ownable.OwnableUnauthorizedAccount.selector,
                address(this)
            )
        );
        dynamis.unpause();

        // Unpausing.

        vm.startPrank(owner);

        dynamis.unpause();

        vm.stopPrank();

        // Minting after unpausing.

        params.quantity = 1;
        params.costSingle = costSingleUSDT[uint8(Type.FIRST)];
        params.cost = params.quantity * params.costSingle;
        params.token = _USDT;
        params.errorSelector = 0x0;

        _mintHelper(params);

        params.quantity = 100;
        params.costSingle = costSingleEth[uint8(Type.FIRST)];
        params.cost = params.quantity * params.costSingle;
        params.token = _ETH;
        params.errorSelector = 0x0;

        _mintHelper(params);
    }

    function test_Vesting() external {
        // Mint params.

        MintParams memory params = MintParams({
            quantity: 0,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        uint8 typeIndex = uint8(Type.FIRST);
        uint256 startTimestamp = windows[typeIndex].startTimestamp + 1;
        vm.warp(startTimestamp);

        params.costSingle = costSingleEth[typeIndex];
        params.token = _ETH;

        // Minting.

        params.quantity = 1;
        params.cost = params.quantity * params.costSingle;
        params.caller = address(this);

        _mintHelper(params);

        // Checking revert on transfer.

        uint256 tokenId = 1;

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.transferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(
            address(this),
            secondary,
            tokenId,
            new bytes(0x00)
        );

        // Minting.

        params.quantity = 10;
        params.cost = params.quantity * params.costSingle;
        params.caller = address(this);

        _mintHelper(params);

        // Checking revert on transfer.

        tokenId = 5;

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.transferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(
            address(this),
            secondary,
            tokenId,
            new bytes(0x00)
        );

        // Minting.

        params.quantity = 1;
        params.cost = params.quantity * params.costSingle;
        params.caller = secondary;

        vm.deal(secondary, params.cost);
        vm.startPrank(secondary);

        _mintHelper(params);

        // Checking revert on transfer.

        tokenId = 12;

        dynamis.approve(tertiary, tokenId);

        vm.startPrank(tertiary);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Minting.

        params.quantity = 10;
        params.cost = params.quantity * params.costSingle;
        params.caller = secondary;

        vm.deal(secondary, params.cost);
        vm.startPrank(secondary);

        _mintHelper(params);

        // Checking revert on transfer.

        tokenId = 22;

        dynamis.approve(tertiary, tokenId);

        vm.startPrank(tertiary);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Checking revert on transfer.

        tokenId = 12;

        vm.startPrank(secondary);
        vm.warp(startTimestamp + dynamis.VESTING_DURATION() - 1);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.transferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(secondary, address(this), tokenId);

        vm.expectRevert(DynamisErrors.Vested.selector);
        dynamis.safeTransferFrom(
            secondary,
            address(this),
            tokenId,
            new bytes(0x00)
        );

        // Transferring.

        tokenId = 22;
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

        // Transferring.

        tokenId = 12;

        dynamis.transferFrom(secondary, tertiary, tokenId);
        dynamis.transferFrom(secondary, tertiary, tokenId + 1);
        dynamis.transferFrom(secondary, tertiary, tokenId + 2);

        // Transferring.

        vm.startPrank(tertiary);

        dynamis.transferFrom(tertiary, address(this), tokenId);
        dynamis.safeTransferFrom(tertiary, address(this), tokenId + 1);
        dynamis.safeTransferFrom(
            tertiary,
            address(this),
            tokenId + 2,
            new bytes(0x00)
        );

        vm.stopPrank();
    }

    function test_Rewards() external {
        // Mint params.

        MintParams memory mintParams = MintParams({
            quantity: 0,
            costSingle: 0,
            cost: 0,
            caller: address(this),
            token: IERC20(address(0)),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        uint8 typeIndex = uint8(Type.FIRST);
        uint256 startTimestamp = windows[typeIndex].startTimestamp + 1;
        vm.warp(startTimestamp);

        mintParams.costSingle = costSingleEth[typeIndex];
        mintParams.token = _ETH;

        // Minting.

        mintParams.quantity = 10;
        mintParams.cost = mintParams.quantity * mintParams.costSingle;
        mintParams.caller = address(this);

        _mintHelper(mintParams);

        // // Minting.

        // mintParams.quantity = 10;
        // mintParams.cost = mintParams.quantity * mintParams.costSingle;
        // mintParams.caller = secondary;

        // vm.deal(secondary, mintParams.cost);
        // vm.startPrank(secondary);

        // _mintHelper(mintParams);

        // // Minting.

        // mintParams.quantity = 10;
        // mintParams.cost = mintParams.quantity * mintParams.costSingle;
        // mintParams.caller = tertiary;

        // vm.deal(tertiary, mintParams.cost);
        // vm.startPrank(tertiary);

        // _mintHelper(mintParams);

        // vm.stopPrank();

        // Claim params.

        ClaimParams memory claimParams = ClaimParams({
            tokenId: 0,
            deadline: 0,
            privateKey: signerPrivateKey,
            caller: address(0),
            dynamis: dynamis,
            errorSelector: 0x0
        });

        // Claiming/

        vm.warp(startTimestamp + (dynamis.REWARD_DURATION() / 6));

        claimParams.tokenId = 5;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = address(this);
        claimParams.errorSelector = 0x0;

        uint256 balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        uint256 balance1 = pai3.balanceOf(claimParams.caller);
        uint256 reward = dynamis.REWARD_PER_SECOND() *
            (dynamis.REWARD_DURATION() / 6);

        assertEq(balance1 - balance0, reward);

        claimParams.tokenId = 8;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = address(this);
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 6);

        assertEq(balance1 - balance0, reward);

        // Transferring.

        vm.warp(startTimestamp + (dynamis.REWARD_DURATION() / 3));

        uint256 tokenId = 1;

        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        tokenId = 2;

        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        tokenId = 5;

        dynamis.safeTransferFrom(address(this), secondary, tokenId);

        // Claiming.

        claimParams.tokenId = 3;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = address(this);
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 3);

        assertEq(balance1 - balance0, reward);

        claimParams.tokenId = 8;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = address(this);
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 6);

        assertEq(balance1 - balance0, reward);

        // Claiming

        vm.startPrank(secondary);

        claimParams.tokenId = 1;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 3);

        assertEq(balance1 - balance0, reward);

        // Checking revert on claim.

        claimParams.tokenId = 1;
        claimParams.deadline = vm.getBlockTimestamp() + 1;
        claimParams.caller = secondary;
        claimParams.errorSelector = DynamisErrors.InsufficientReward.selector;

        _claimHelper(claimParams);

        // Transferring.

        tokenId = 1;

        dynamis.safeTransferFrom(secondary, tertiary, tokenId);

        // Checking revert on claim.

        claimParams.tokenId = 1;
        claimParams.deadline = vm.getBlockTimestamp() + 1;
        claimParams.caller = secondary;
        claimParams.errorSelector = DynamisErrors.CallerNotOwner.selector;

        _claimHelper(claimParams);

        // Claiming.

        vm.warp(startTimestamp + ((dynamis.REWARD_DURATION() * 2) / 3));

        claimParams.tokenId = 5;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 2);

        assertEq(balance1 - balance0, reward);

        // Claiming.

        vm.warp(startTimestamp + dynamis.REWARD_DURATION());

        claimParams.tokenId = 2;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * dynamis.REWARD_DURATION();

        assertEq(balance1 - balance0, reward);

        claimParams.tokenId = 5;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = 0x0;

        balance0 = pai3.balanceOf(claimParams.caller);

        _claimHelper(claimParams);

        balance1 = pai3.balanceOf(claimParams.caller);
        reward = dynamis.REWARD_PER_SECOND() * (dynamis.REWARD_DURATION() / 3);

        assertEq(balance1 - balance0, reward);

        // Checking revert on claim.

        vm.warp(startTimestamp + dynamis.REWARD_DURATION() + 1);

        claimParams.tokenId = 2;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = DynamisErrors.InsufficientReward.selector;

        _claimHelper(claimParams);

        vm.warp(startTimestamp + (dynamis.REWARD_DURATION() * 2));

        claimParams.tokenId = 5;
        claimParams.deadline = vm.getBlockTimestamp();
        claimParams.caller = secondary;
        claimParams.errorSelector = DynamisErrors.InsufficientReward.selector;

        _claimHelper(claimParams);

        vm.stopPrank();
    }
}
