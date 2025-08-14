// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;


import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Simple ERC20 MultiSig Wallet
 * @notice A beginner-friendly multisig wallet for ERC20 tokens
 * @dev This contract requires multiple owners to approve token transfers
 */
contract SimpleERC20Multisig {
    // We'll add state variables here

    // --- State Variables ---
    address[] public owners; // List of wallet owners
    mapping(address => bool) public isOwner; // Quick owner lookup
    uint256 public threshold; // How many approvals needed
    address public token; // Which ERC20 token we manage
    uint256 public tokenBalance; // Track our token balance

    // --- Transaction Structure ---
    struct Transaction {
        address to; // Where to send tokens
        uint256 amount; // How many tokens to send
        bool executed; // Has this been executed?
        uint256 confirmations; // How many owners approved this
    }

    Transaction[] public transactions;

    // Track which owners confirmed which transactions
    // Format: transactionId => owner => hasConfirmed
    mapping(uint256 => mapping(address => bool)) public hasConfirmed;

    //_threshold is the number of owners that need to confirm
    constructor(address[] memory _owners, uint256 _threshold, address _token) {
        // Basic validation
        require(_owners.length > 0, "Need at least one owner");
        require(
            _threshold > 0 && _threshold <= _owners.length,
            "Invalid threshold"
        );
        require(_token != address(0), "Token address cannot be zero");

        // Set up owners
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Owner cannot be zero address");
            require(!isOwner[owner], "Duplicate owner");

            isOwner[owner] = true;
            owners.push(owner);
        }

        threshold = _threshold;
        token = _token;
        tokenBalance = 0;
    }

    /**
    * @notice Deposit tokens into the multisig wallet
    * @param amount Amount of tokens to deposit
    */
    function depositTokens(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        // Transfer tokens from sender to this contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        // uint256 tokenBalance = IERC20(token).balanceOf(address(this));
        tokenBalance += amount;
    }

    /**
    * @notice Submit a new transaction proposal
    * @param to Address to send tokens to
    * @param amount Amount of tokens to send
    * @return txId The ID of the created transaction
    */
    function submitTransaction(
        address to,
        uint256 amount
    ) external returns (uint256 txId) {
        // Only owners can submit transactions
        require(isOwner[msg.sender], "Only owners can submit transactions");
        require(to != address(0), "Cannot send to zero address");
        require(amount > 0, "Amount must be greater than zero");
        // Check if there is enough balance
        require(tokenBalance >= amount, "Not enough balance");

        // Create new transaction
        transactions.push(
            Transaction({
                to: to,
                amount: amount,
                executed: false,
                confirmations: 0
            })
        );

        // Return the index of the new transaction
        txId = transactions.length - 1;
    }

    /**
    * @notice Confirm a pending transaction
    * @param txId ID of the transaction to confirm
    */
    function confirmTransaction(uint256 txId) external {
        // Basic checks
        require(isOwner[msg.sender], "Only owners can confirm");
        require(txId < transactions.length, "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction already executed");
        require(
            !hasConfirmed[txId][msg.sender],
            "Already confirmed by this owner"
        );

        // Check if enough owners have confirmed
        // require(
        //     transactions[txId].confirmations + 1 >= threshold,
        //     "Not enough owners have confirmed"
        // );

        // Record the confirmation
        hasConfirmed[txId][msg.sender] = true;
        transactions[txId].confirmations += 1;
    }

    /**
    * @notice Execute a transaction if it has enough confirmations
    * @param txId ID of the transaction to execute
    */
    function executeTransaction(uint256 txId) external {
        // Basic checks
        require(isOwner[msg.sender], "Only owners can execute");
        require(txId < transactions.length, "Transaction does not exist");
        require(!transactions[txId].executed, "Transaction already executed");
        require(
            transactions[txId].confirmations >= threshold,
            "Not enough confirmations"
        );

        // Check if we have enough tokens
        Transaction memory txn = transactions[txId];
        require(tokenBalance >= txn.amount, "Insufficient token balance");

        // Mark as executed first (prevents reentrancy)
        transactions[txId].executed = true;

        // Send the tokens and update balance
        IERC20(token).transfer(txn.to, txn.amount);
        tokenBalance -= txn.amount;
    }
}