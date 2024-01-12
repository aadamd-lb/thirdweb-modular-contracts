// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.0;

interface ITokenHook {
    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted on an attempt to call a hook that is not implemented.
    error TokenHookNotImplemented();

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the number of hooks implemented by the contract.
    function getHooksImplemented() external view returns (uint256 hooksImplemented);

    /// @notice Returns the signature of the arguments expected by the beforeMint hook.
    function getBeforeMintArgSignature() external view returns (string memory argSignature);

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice The beforeMint hook that is called by a core token before minting a token.
     *  @param to The address that is minting tokens.
     *  @param quantity The quantity of tokens to mint.
     *  @param encodedArgs The encoded arguments for the beforeMint hook.
     *  @return tokenIdToMint The token ID to start minting the given quantity tokens from.
     *  @return quantityToMint The quantity of tokens to mint.
     */
    function beforeMint(address to, uint256 quantity, bytes memory encodedArgs)
        external
        payable
        returns (uint256 tokenIdToMint, uint256 quantityToMint);

    /**
     *  @notice The beforeTransfer hook that is called by a core token before transferring a token.
     *  @param from The address that is transferring tokens.
     *  @param to The address that is receiving tokens.
     *  @param tokenId The token ID being transferred.
     */
    function beforeTransfer(address from, address to, uint256 tokenId) external;

    /**
     *  @notice The beforeBurn hook that is called by a core token before burning a token.
     *  @param from The address that is burning tokens.
     *  @param tokenId The token ID being burned.
     */
    function beforeBurn(address from, uint256 tokenId) external;

    /**
     *  @notice The beforeApprove hook that is called by a core token before approving a token.
     *  @param from The address that is approving tokens.
     *  @param to The address that is being approved.
     *  @param tokenId The token ID being approved.
     */
    function beforeApprove(address from, address to, uint256 tokenId) external;
}
