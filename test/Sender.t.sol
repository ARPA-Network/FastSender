// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {Sender} from "../src/Sender.sol";
import {MockERC20} from "./MockERC20.sol";
import {IERC20Errors} from "openzeppelin-contracts/contracts/interfaces/draft-IERC6093.sol";

contract SenderTest is Test {
    Sender public sender;
    MockERC20 public mock1;
    MockERC20 public mock2;
    address public user = address(0x111111111111);
    address public receiver1 = address(0x222222222222);
    address public receiver2 = address(0x333333333333);
    string private checkpointLabel;
    uint256 private checkpointGasLeft = 1; // Start the slot warm.

    function setUp() public {
        vm.prank(user);
        sender = new Sender();
        mock1 = new MockERC20();
        mock2 = new MockERC20();
    }

    function testSendToken() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 100;
        balances[1] = 200;

        vm.deal(user, 3000);
        vm.prank(user);
        mock1.mint(user, 300);
        vm.prank(user);
        mock1.approve(address(sender), 300);

        assertEq(mock1.balanceOf(user), 300);
        assertEq(mock1.allowance(user, address(sender)), 300);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 0);
        assertEq(mock1.balanceOf(receivers[1]), 0);

        printUserBalance(user);
        printReceiverBalance(receivers);
        emit log_string("-----------------------------------------------");

        vm.prank(user);
        sender.sendToken(address(mock1), receivers, balances);
        assertEq(mock1.balanceOf(user), 0);
        assertEq(mock1.allowance(user, address(sender)), 0);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 100);
        assertEq(mock1.balanceOf(receivers[1]), 200);
        printUserBalance(user);
        printReceiverBalance(receivers);
    }

    function testSendTwoToken() public {
        address[] memory receivers = new address[](2);
        uint256[] memory token1Balances = new uint256[](2);
        uint256[] memory token2Balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        token1Balances[0] = 100;
        token1Balances[1] = 200;
        token2Balances[0] = 10;
        token2Balances[1] = 20;

        vm.deal(user, 3000);
        vm.prank(user);
        mock1.mint(user, 300);
        vm.prank(user);
        mock1.approve(address(sender), 300);
        mock2.mint(user, 30);
        vm.prank(user);
        mock2.approve(address(sender), 30);

        assertEq(mock1.balanceOf(user), 300);
        assertEq(mock1.allowance(user, address(sender)), 300);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 0);
        assertEq(mock1.balanceOf(receivers[1]), 0);
        assertEq(mock2.balanceOf(user), 30);
        assertEq(mock2.allowance(user, address(sender)), 30);
        assertEq(mock2.balanceOf(address(sender)), 0);
        assertEq(mock2.balanceOf(receivers[0]), 0);
        assertEq(mock2.balanceOf(receivers[1]), 0);

        printUserBalance(user);
        printReceiverBalance(receivers);
        emit log_string("-----------------------------------------------");

        vm.prank(user);
        sender.sendTwoToken(address(mock1), address(mock2), receivers, token1Balances, token2Balances);
        assertEq(mock1.balanceOf(user), 0);
        assertEq(mock1.allowance(user, address(sender)), 0);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 100);
        assertEq(mock1.balanceOf(receivers[1]), 200);
        assertEq(mock2.balanceOf(user), 0);
        assertEq(mock2.allowance(user, address(sender)), 0);
        assertEq(mock2.balanceOf(address(sender)), 0);
        assertEq(mock2.balanceOf(receivers[0]), 10);
        assertEq(mock2.balanceOf(receivers[1]), 20);
        printUserBalance(user);
        printReceiverBalance(receivers);
    }

    function testSendEther() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 10;
        balances[1] = 20;

        vm.deal(user, 3000);
        vm.prank(user);

        assertEq(user.balance, 3000);
        assertEq(receivers[0].balance, 0);
        assertEq(receivers[1].balance, 0);

        printUserBalance(user);
        printReceiverBalance(receivers);
        emit log_string("-----------------------------------------------");

        vm.prank(user);
        sender.sendEther{value: 30}(receivers, balances);
        assertEq(user.balance, 2970);
        assertEq(receivers[0].balance, 10);
        assertEq(receivers[1].balance, 20);
        printUserBalance(user);
        printReceiverBalance(receivers);
    }

    function testSendTokenAndEther() public {
        address[] memory receivers = new address[](2);
        uint256[] memory tokenBalances = new uint256[](2);
        uint256[] memory etherBalances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        tokenBalances[0] = 100;
        tokenBalances[1] = 200;
        etherBalances[0] = 10;
        etherBalances[1] = 20;

        vm.deal(user, 3000);
        vm.prank(user);
        mock1.mint(user, 300);
        vm.prank(user);
        mock1.approve(address(sender), 300);

        assertEq(mock1.balanceOf(user), 300);
        assertEq(mock1.allowance(user, address(sender)), 300);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 0);
        assertEq(mock1.balanceOf(receivers[1]), 0);
        assertEq(user.balance, 3000);
        assertEq(receivers[0].balance, 0);
        assertEq(receivers[1].balance, 0);

        printUserBalance(user);
        printReceiverBalance(receivers);
        emit log_string("-----------------------------------------------");

        vm.prank(user);
        sender.sendTokenAndEther{value: 30}(address(mock1), receivers, tokenBalances, etherBalances);
        assertEq(mock1.balanceOf(user), 0);
        assertEq(mock1.allowance(user, address(sender)), 0);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 100);
        assertEq(mock1.balanceOf(receivers[1]), 200);
        assertEq(user.balance, 2970);
        assertEq(receivers[0].balance, 10);
        assertEq(receivers[1].balance, 20);
        printUserBalance(user);
        printReceiverBalance(receivers);
    }

    function testClaimTokens() public {
        vm.deal(address(sender), 300);
        vm.prank(user);
        mock1.mint(address(sender), 3000);
        assertEq(user.balance, 0);
        assertEq(mock1.balanceOf(user), 0);

        vm.prank(user);
        sender.claimTokens(address(0x0));
        assertEq(user.balance, 300);
        vm.prank(user);
        sender.claimTokens(address(mock1));
        assertEq(mock1.balanceOf(user), 3000);
        printUserBalance(user);
    }

    function testNotEnoughTokenAllowance() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 10;
        balances[1] = 20;

        vm.deal(user, 3000);
        vm.prank(user);
        mock1.mint(user, 300);
        vm.prank(user);
        mock1.approve(address(sender), 15);

        assertEq(mock1.balanceOf(user), 300);
        assertEq(mock1.allowance(user, address(sender)), 15);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 0);
        assertEq(mock1.balanceOf(receivers[1]), 0);

        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(sender), 5, 20)
        );
        sender.sendToken(address(mock1), receivers, balances);
    }

    function testNotEnoughTokenBalance() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 10;
        balances[1] = 20;

        vm.deal(user, 3000);
        vm.prank(user);
        mock1.mint(user, 5);
        vm.prank(user);
        mock1.approve(address(sender), 30);

        assertEq(mock1.balanceOf(user), 5);
        assertEq(mock1.allowance(user, address(sender)), 30);
        assertEq(mock1.balanceOf(address(sender)), 0);
        assertEq(mock1.balanceOf(receivers[0]), 0);
        assertEq(mock1.balanceOf(receivers[1]), 0);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IERC20Errors.ERC20InsufficientBalance.selector, user, 5, 10));
        sender.sendToken(address(mock1), receivers, balances);
    }

    function testNotEnoughEther() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 10;
        balances[1] = 20;

        vm.deal(user, 3000);

        assertEq(user.balance, 3000);
        assertEq(receivers[0].balance, 0);
        assertEq(receivers[1].balance, 0);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Sender.NotEnoughEther.selector));
        sender.sendEther{value: 15}(receivers, balances);
    }

    function testTooMuchEther() public {
        address[] memory receivers = new address[](2);
        uint256[] memory balances = new uint256[](2);
        receivers[0] = receiver1;
        receivers[1] = receiver2;
        balances[0] = 10;
        balances[1] = 20;

        vm.deal(user, 3000);

        assertEq(user.balance, 3000);
        assertEq(receivers[0].balance, 0);
        assertEq(receivers[1].balance, 0);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Sender.TooMuchEther.selector));
        sender.sendEther{value: 35}(receivers, balances);
    }

    function testSendEtherToMaxReceivers() public {
        uint256 maxReceivers = sender.MAX_RECEIVERS();
        address[] memory receivers = new address[](maxReceivers);
        uint256[] memory balances = new uint256[](maxReceivers);
        for (uint160 i = 0; i < maxReceivers; i++) {
            receivers[i] = address(uint160(receiver1) + i);
            balances[i] = 10;
        }

        vm.deal(user, maxReceivers * 100);

        for (uint256 i = 0; i < maxReceivers; i++) {
            assertEq(receivers[i].balance, 0);
        }

        vm.prank(user);
        startMeasuringGas("SendEtherToMaxReceivers");
        sender.sendEther{value: maxReceivers * 10}(receivers, balances);
        uint256 gasDelta = stopMeasuringGas();
        assertGe(3000000, gasDelta);

        for (uint256 i = 0; i < maxReceivers; i++) {
            assertEq(receivers[i].balance, 10);
        }
    }

    function testSendTwoTokenToMaxReceivers() public {
        uint256 maxReceivers = sender.MAX_RECEIVERS();
        address[] memory receivers = new address[](maxReceivers);
        uint256[] memory token1Balances = new uint256[](maxReceivers);
        uint256[] memory token2Balances = new uint256[](maxReceivers);
        for (uint160 i = 0; i < maxReceivers; i++) {
            receivers[i] = address(uint160(receiver1) + i);
            token1Balances[i] = 10;
            token2Balances[i] = 20;
        }

        vm.deal(user, 1e18);

        vm.prank(user);
        mock1.mint(user, 10 * maxReceivers);
        vm.prank(user);
        mock1.approve(address(sender), 10 * maxReceivers);

        mock2.mint(user, 20 * maxReceivers);
        vm.prank(user);
        mock2.approve(address(sender), 20 * maxReceivers);
        assertEq(mock2.allowance(user, address(sender)), 20 * maxReceivers);

        for (uint256 i = 0; i < maxReceivers; i++) {
            assertEq(mock1.balanceOf(receivers[i]), 0);
            assertEq(mock2.balanceOf(receivers[i]), 0);
        }

        vm.prank(user);
        startMeasuringGas("SendTwoTokenToMaxReceivers");
        sender.sendTwoToken(address(mock1), address(mock2), receivers, token1Balances, token2Balances);
        uint256 gasDelta = stopMeasuringGas();
        assertGe(3000000, gasDelta);

        for (uint256 i = 0; i < maxReceivers; i++) {
            assertEq(mock1.balanceOf(receivers[i]), 10);
            assertEq(mock2.balanceOf(receivers[i]), 20);
        }
    }

    function testTooManyReceivers() public {
        uint256 maxReceivers = sender.MAX_RECEIVERS();
        address[] memory receivers = new address[](maxReceivers + 1);
        uint256[] memory balances = new uint256[](maxReceivers + 1);
        for (uint160 i = 0; i < maxReceivers + 1; i++) {
            receivers[i] = address(uint160(receiver1) + i);
            balances[i] = 10;
        }

        vm.deal(user, 3000);

        for (uint256 i = 0; i < maxReceivers + 1; i++) {
            assertEq(receivers[i].balance, 0);
        }

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(Sender.TooManyReceivers.selector));
        sender.sendEther{value: 35}(receivers, balances);

        for (uint256 i = 0; i < maxReceivers + 1; i++) {
            assertEq(receivers[i].balance, 0);
        }
    }

    function printUserBalance(address _user) internal {
        emit log_named_address("user", _user);
        emit log_named_uint("ether balance", _user.balance);
        emit log_named_uint("token1 balance", mock1.balanceOf(_user));
        emit log_named_uint("token2 balance", mock2.balanceOf(_user));
    }

    function printReceiverBalance(address[] memory receivers) internal {
        for (uint256 i = 0; i < receivers.length; i++) {
            emit log_named_address("receiver", receivers[i]);
            emit log_named_uint("ether balance", receivers[i].balance);
            emit log_named_uint("token1 balance", mock1.balanceOf(receivers[i]));
            emit log_named_uint("token2 balance", mock2.balanceOf(receivers[i]));
        }
    }

    function startMeasuringGas(string memory label) internal virtual {
        checkpointLabel = label;
        checkpointGasLeft = gasleft();
    }

    function stopMeasuringGas() internal virtual returns (uint256 gasDelta) {
        uint256 checkpointGasLeft2 = gasleft();
        // Subtract 100 to account for the warm SLOAD in startMeasuringGas.
        gasDelta = checkpointGasLeft - checkpointGasLeft2 - 100;
        emit log_named_uint(string(abi.encodePacked(checkpointLabel, " Gas")), gasDelta);
    }
}
