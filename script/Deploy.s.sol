// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Script.sol";
import "../src/SimpleERC20Multisig.sol";

/**
 * @title Deploy Script for SimpleERC20Multisig
 * @notice Deployment script with hardcoded local configuration
 * @dev Uses locally defined owners, threshold, and token address
 */
contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        // Get configuration from local hardcoded values
        address[] memory owners = getOwners();
        uint256 threshold = getThreshold();
        address tokenAddress = getTokenAddress();

        // Validate configuration
        require(owners.length > 0, "At least one owner required");
        require(
            threshold > 0 && threshold <= owners.length,
            "Invalid threshold"
        );
        require(tokenAddress != address(0), "Token address required");

        // Deploy the multisig contract
        SimpleERC20Multisig multisig = new SimpleERC20Multisig(
            owners,
            threshold,
            tokenAddress
        );

        // Log deployment information
        console.log("=== SimpleERC20Multisig Deployment Complete ===");
        console.log("Contract Address:", address(multisig));
        console.log("Token Address:", tokenAddress);
        console.log("Threshold:", threshold);
        console.log("Number of Owners:", owners.length);

        console.log("Owners:");
        for (uint256 i = 0; i < owners.length; i++) {
            console.log("  [%d] %s", i + 1, owners[i]);
        }
        console.log("===============================================");

        vm.stopBroadcast();
    }

    /**
     * @notice Get owner addresses (hardcoded for local deployment)
     */
    function getOwners() internal pure returns (address[] memory) {
        // Use hardcoded owner addresses for local deployment
        console.log("Using locally configured owner addresses");
        address[] memory owners = new address[](3);
        owners[0] = 0xd56279982a6363aD04d8DF8965F4702554AD0553;
        owners[1] = 0x787EC23276D87DF482553A1C03bD9C8DB52F4bda;
        owners[2] = 0x9AFe124c2eB056F5104b82134B3f6F1F30422612;
        return owners;
    }

    /**
     * @notice Get threshold (hardcoded for local deployment)
     */
    function getThreshold() internal pure returns (uint256) {
        // Use hardcoded threshold for local deployment
        console.log("Using locally configured threshold: 2");
        return 2;
    }

    /**
     * @notice Get token address (hardcoded for local deployment)
     */
    function getTokenAddress() internal pure returns (address) {
        // Use hardcoded token address for local deployment (cUSD on Alfajores)
        console.log("Using locally configured token: cUSD on Alfajores");
        return 0xe6A57340f0df6E020c1c0a80bC6E13048601f0d4;
    }
}