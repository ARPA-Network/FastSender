// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {IERC20, SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";

contract Sender is Ownable {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_RECEIVERS = 50;

    event TokenSended(address indexed sender, address indexed tokenAddress, uint256 ethTotal, uint256 tokenTotal);
    event ClaimedTokens(address indexed token, address owner, uint256 balance);

    error TooManyReceivers();
    error NotEnoughEther();
    error TooMuchEther();

    constructor() Ownable(msg.sender) {}

    function sendToken(address token, address[] calldata receivers, uint256[] calldata balances) public {
        uint256 total = 0;
        if (receivers.length > MAX_RECEIVERS) {
            revert TooManyReceivers();
        }
        IERC20 erc20token = IERC20(token);
        for (uint256 i = 0; i < receivers.length; i++) {
            total += balances[i];
            erc20token.safeTransferFrom(msg.sender, receivers[i], balances[i]);
        }
        emit TokenSended(msg.sender, token, 0, total);
    }

    function sendTwoToken(
        address token1,
        address token2,
        address[] calldata receivers,
        uint256[] calldata token1Balances,
        uint256[] calldata token2Balances
    ) public {
        uint256 total1 = 0;
        uint256 total2 = 0;
        if (receivers.length > MAX_RECEIVERS) {
            revert TooManyReceivers();
        }
        IERC20 erc20token1 = IERC20(token1);
        IERC20 erc20token2 = IERC20(token2);
        for (uint256 i = 0; i < receivers.length; i++) {
            total1 += token1Balances[i];
            total2 += token2Balances[i];
            erc20token1.safeTransferFrom(msg.sender, receivers[i], token1Balances[i]);
            erc20token2.safeTransferFrom(msg.sender, receivers[i], token2Balances[i]);
        }
        emit TokenSended(msg.sender, token1, 0, total1);
        emit TokenSended(msg.sender, token2, 0, total2);
    }

    function sendEther(address[] calldata receivers, uint256[] calldata balances) public payable {
        uint256 ethLeft = msg.value;
        if (receivers.length > MAX_RECEIVERS) {
            revert TooManyReceivers();
        }
        for (uint256 i = 0; i < receivers.length; i++) {
            if (ethLeft < balances[i]) {
                revert NotEnoughEther();
            }
            ethLeft -= balances[i];
            payable(receivers[i]).transfer(balances[i]);
        }
        if (ethLeft > 0) {
            revert TooMuchEther();
        }
        emit TokenSended(msg.sender, address(0x0), msg.value, 0);
    }

    function sendTokenAndEther(
        address token,
        address[] calldata receivers,
        uint256[] calldata tokenBalances,
        uint256[] calldata etherBalances
    ) public payable {
        uint256 ethLeft = msg.value;
        uint256 tokenTotal = 0;
        if (receivers.length > MAX_RECEIVERS) {
            revert TooManyReceivers();
        }
        IERC20 erc20token = IERC20(token);
        for (uint256 i = 0; i < receivers.length; i++) {
            if (ethLeft < etherBalances[i]) {
                revert NotEnoughEther();
            }
            ethLeft -= etherBalances[i];
            tokenTotal += tokenBalances[i];
            payable(receivers[i]).transfer(etherBalances[i]);
            erc20token.safeTransferFrom(msg.sender, receivers[i], tokenBalances[i]);
        }
        if (ethLeft > 0) {
            revert TooMuchEther();
        }
        emit TokenSended(msg.sender, token, msg.value, tokenTotal);
    }

    function claimTokens(address token) public onlyOwner {
        if (token == address(0x0)) {
            payable(msg.sender).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.safeTransfer(msg.sender, balance);
        emit ClaimedTokens(token, msg.sender, balance);
    }
}
