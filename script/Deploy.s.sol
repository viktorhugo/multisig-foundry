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
    function getOwners() internal view returns (address[] memory) {
        string memory ownersStr = vm.envString("OWNERS");
        require(bytes(ownersStr).length > 0, "OWNERS env var not set");
        string[] memory ownersArr = new string[](10);
        uint count = 0;
        bytes memory ownersBytes = bytes(ownersStr);
        uint start = 0;
        for(uint i=0; i<ownersBytes.length; i++){
            if(ownersBytes[i] == ','){
                ownersArr[count] = new string(i-start);
                bytes memory owner = bytes(ownersArr[count]);
                for(uint j=0; j<owner.length; j++){
                    owner[j] = ownersBytes[start+j];
                }
                count++;
                start = i+1;
            }
        }
        ownersArr[count] = new string(ownersBytes.length-start);
        bytes memory ownerBytes = bytes(ownersArr[count]);
        for(uint j=0; j<ownerBytes.length; j++){
            ownerBytes[j] = ownersBytes[start+j];
        }
        count++;

        address[] memory owners = new address[](count);
        for(uint i=0; i<count; i++){
            owners[i] = vm.parseAddress(ownersArr[i]);
        }

        return owners;
    }

    /**
     * @notice Get threshold from environment variable
     */
    function getThreshold() internal view returns (uint256) {
        uint256 threshold = vm.envUint("THRESHOLD");
        require(threshold > 0, "THRESHOLD env var not set");
        return threshold;
    }

    /**
     * @notice Get token address from environment variable
     */
    function getTokenAddress() internal view returns (address) {
        address tokenAddress = vm.envAddress("TOKEN_ADDRESS");
        require(tokenAddress != address(0), "TOKEN_ADDRESS env var not set");
        return tokenAddress;
    }
}