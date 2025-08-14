// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {SimpleERC20Multisig} from "../src/SimpleERC20Multisig.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract SimpleERC20MultisigTest is Test {
        // --- Test Infrastructure ---
    SimpleERC20Multisig public multisig; // Our contract under test
    ERC20Mock public token; // Mock ERC20 for isolated testing

    // Test addresses - using simple addresses for clarity
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public recipient = address(0x5);

    // Configuration
    address[] public owners;
    uint256 public threshold = 2; // Require 2 out of 3 approvals

    function setUp() public {
        // 1. Create mock ERC20 token for testing
        token = new ERC20Mock();

        // 2. Set up owners array
        owners = [owner1, owner2, owner3];

        // 3. Deploy our multisig contract
        multisig = new SimpleERC20Multisig(owners, threshold, address(token));

        // 4. Give tokens to owner1 for testing deposits
        token.mint(owner1, 1000 ether);

        // 5. Approve multisig to spend owner1's tokens
        vm.prank(owner1);
        token.approve(address(multisig), 1000 ether);
    }

    /// @notice Test the complete happy path workflow of the multisig
    function testHappyPathWorkflow() public {
        uint256 depositAmount = 200 ether;
        uint256 transferAmount = 50 ether;

        // 1. Deposit tokens into the multisig
        vm.prank(owner1);
        multisig.depositTokens(depositAmount);

        // Verify deposit was successful
        assertEq(multisig.tokenBalance(), depositAmount);
        assertEq(token.balanceOf(address(multisig)), depositAmount);

        // 2. Submit a transaction proposal
        vm.prank(owner1);
        uint256 txId = multisig.submitTransaction(recipient, transferAmount);

        // Verify transaction was created correctly
        (
            address to,
            uint256 amount,
            bool executed,
            uint256 confirmations
        ) = multisig.transactions(txId);

        assertEq(to, recipient);
        assertEq(amount, transferAmount);
        assertFalse(executed);
        assertEq(confirmations, 0);

        // 3. First owner confirms the transaction
        vm.prank(owner1);
        multisig.confirmTransaction(txId);

        // Verify first confirmation
        assertTrue(multisig.hasConfirmed(txId, owner1));
        (, , , confirmations) = multisig.transactions(txId);
        assertEq(confirmations, 1);

        // 4. Second owner confirms (reaches threshold of 2)
        vm.prank(owner2);
        multisig.confirmTransaction(txId);

        // Verify second confirmation
        assertTrue(multisig.hasConfirmed(txId, owner2));
        (, , , confirmations) = multisig.transactions(txId);
        assertEq(confirmations, 2);

        // 5. Execute the transaction
        uint256 recipientBalanceBefore = token.balanceOf(recipient);

        vm.prank(owner1);
        multisig.executeTransaction(txId);

        // 6. Verify final state - all balances and transaction status
        (, , executed, ) = multisig.transactions(txId);
        assertTrue(executed);
        assertEq(multisig.tokenBalance(), depositAmount - transferAmount);
        assertEq(
            token.balanceOf(recipient),
            recipientBalanceBefore + transferAmount
        );
        assertEq(
            token.balanceOf(address(multisig)),
            depositAmount - transferAmount
        );

        // Optional: Log results for debugging
        console.log("Happy path test completed successfully!");
        console.log("Multisig balance:", multisig.tokenBalance());
        console.log("Recipient balance:", token.balanceOf(recipient));
    }
}