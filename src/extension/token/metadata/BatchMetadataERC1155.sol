// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {BatchMetadataERC721} from "./BatchMetadataERC721.sol";

contract BatchMetadataERC1155 is BatchMetadataERC721 {
    /// @notice Returns all implemented callback and extension functions.
    function getExtensionConfig() external pure virtual override returns (ExtensionConfig memory config) {
        config.callbackFunctions = new CallbackFunction[](1);
        config.fallbackFunctions = new FallbackFunction[](2);

        config.callbackFunctions[0] = CallbackFunction(this.onTokenURI.selector, CallType.STATICCALL);
        config.fallbackFunctions[0] = FallbackFunction({
            selector: this.uploadMetadata.selector,
            callType: CallType.CALL,
            permissionBits: TOKEN_ADMIN_ROLE
        });
        config.fallbackFunctions[1] = FallbackFunction({
            selector: this.getAllMetadataBatches.selector,
            callType: CallType.STATICCALL,
            permissionBits: 0
        });

        config.requiredInterfaceId = 0xd9b67a26; // ERC1155
    }
}