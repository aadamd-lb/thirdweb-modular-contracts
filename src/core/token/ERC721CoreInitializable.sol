// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import {Initializable} from "@solady/utils/Initializable.sol";
import {Multicallable} from "@solady/utils/Multicallable.sol";
import {
    IERC721AUpgradeable,
    ERC721AUpgradeable,
    ERC721AQueryableUpgradeable
} from "@erc721a-upgradeable/extensions/ERC721AQueryableUpgradeable.sol";

import {ModularCoreUpgradeable} from "../../ModularCoreUpgradeable.sol";

import {BeforeMintCallbackERC721} from "../../callback/BeforeMintCallbackERC721.sol";
import {BeforeTransferCallbackERC721} from "../../callback/BeforeTransferCallbackERC721.sol";
import {BeforeBurnCallbackERC721} from "../../callback/BeforeBurnCallbackERC721.sol";
import {BeforeApproveCallbackERC721} from "../../callback/BeforeApproveCallbackERC721.sol";
import {BeforeApproveForAllCallback} from "../../callback/BeforeApproveForAllCallback.sol";
import {OnTokenURICallback} from "../../callback/OnTokenURICallback.sol";

contract ERC721CoreInitializable is
    ERC721AQueryableUpgradeable,
    ModularCoreUpgradeable,
    Multicallable,
    Initializable
{
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice The contract metadata URI of the contract.
    string private _contractURI;

    /*//////////////////////////////////////////////////////////////
                               EVENTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the contract URI is updated.
    event ContractURIUpdated();

    /*//////////////////////////////////////////////////////////////
                            CONSTRUCTOR & INITIALIZER
    //////////////////////////////////////////////////////////////*/

    constructor(address _erc1967Factory) ModularCoreUpgradeable(_erc1967Factory) {
        _disableInitializers();
    }

    function initialize(
        string memory name,
        string memory symbol,
        string memory contractURI,
        address owner,
        address[] memory extensions,
        bytes[] memory extensionInstallData
    ) external payable initializer initializerERC721A {
        // Set contract metadata
        __ERC721A_init(name, symbol);
        _setupContractURI(contractURI);
        _initializeOwner(owner);

        // Install and initialize extensions
        require(extensions.length == extensions.length);
        for (uint256 i = 0; i < extensions.length; i++) {
            _installExtension(extensions[i], extensionInstallData[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////
                              VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Returns the contract URI of the contract.
     *  @return uri The contract URI of the contract.
     */
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

    /**
     *  @notice Returns the token metadata of an NFT.
     *  @dev Always returns metadata queried from the metadata source.
     *  @param id The token ID of the NFT.
     *  @return metadata The URI to fetch metadata from.
     */
    function tokenURI(uint256 id)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable)
        returns (string memory)
    {
        return _getTokenURI(id);
    }

    /**
     *  @notice Returns whether the contract implements an interface with the given interface ID.
     *  @param interfaceId The interface ID of the interface to check for
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721AUpgradeable, IERC721AUpgradeable, ModularCoreUpgradeable)
        returns (bool)
    {
        return interfaceId == 0x01ffc9a7 // ERC165 Interface ID for ERC165
            || interfaceId == 0x80ac58cd // ERC165 Interface ID for ERC721
            || interfaceId == 0x5b5e139f // ERC165 Interface ID for ERC721Metadata
            || interfaceId == 0x2a55205a // ERC165 Interface ID for ERC-2981
            || super.supportsInterface(interfaceId); // right-most ModularCore
    }

    function getSupportedCallbackFunctions()
        public
        pure
        override
        returns (SupportedCallbackFunction[] memory supportedCallbackFunctions)
    {
        supportedCallbackFunctions = new SupportedCallbackFunction[](6);
        supportedCallbackFunctions[0] = SupportedCallbackFunction({
            selector: BeforeMintCallbackERC721.beforeMintERC721.selector,
            mode: CallbackMode.REQUIRED
        });
        supportedCallbackFunctions[1] = SupportedCallbackFunction({
            selector: BeforeTransferCallbackERC721.beforeTransferERC721.selector,
            mode: CallbackMode.OPTIONAL
        });
        supportedCallbackFunctions[2] = SupportedCallbackFunction({
            selector: BeforeBurnCallbackERC721.beforeBurnERC721.selector,
            mode: CallbackMode.OPTIONAL
        });
        supportedCallbackFunctions[3] = SupportedCallbackFunction({
            selector: BeforeApproveCallbackERC721.beforeApproveERC721.selector,
            mode: CallbackMode.OPTIONAL
        });
        supportedCallbackFunctions[4] = SupportedCallbackFunction({
            selector: BeforeApproveForAllCallback.beforeApproveForAll.selector,
            mode: CallbackMode.OPTIONAL
        });
        supportedCallbackFunctions[5] =
            SupportedCallbackFunction({selector: OnTokenURICallback.onTokenURI.selector, mode: CallbackMode.REQUIRED});
    }

    /*//////////////////////////////////////////////////////////////
                        EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     *  @notice Sets the contract URI of the contract.
     *  @dev Only callable by contract admin.
     *  @param uri The contract URI to set.
     */
    function setContractURI(string memory uri) external onlyOwner {
        _setupContractURI(uri);
    }

    /**
     *  @notice Mints a token. Calls the beforeMint hook.
     *  @dev Reverts if beforeMint hook is absent or unsuccessful.
     *  @param to The address to mint the token to.
     *  @param quantity The quantity of tokens to mint.
     *  @param data ABI encoded data to pass to the beforeMint hook.
     */
    function mint(address to, uint256 quantity, bytes calldata data) external payable {
        _beforeMint(to, quantity, data);
        _mint(to, quantity);
    }

    /**
     *  @notice Burns an NFT.
     *  @dev Calls the beforeBurn hook. Skips calling the hook if it doesn't exist.
     *  @param tokenId The token ID of the NFT to burn.
     *  @param data ABI encoded data to pass to the beforeBurn hook.
     */
    function burn(uint256 tokenId, bytes calldata data) external {
        _beforeBurn(msg.sender, tokenId, data);
        _burn(tokenId, true);
    }

    /**
     *  @notice Transfers ownership of an NFT from one address to another.
     *  @dev Overriden to call the beforeTransfer hook. Skips calling the hook if it doesn't exist.
     *  @param from The address to transfer from
     *  @param to The address to transfer to
     *  @param id The token ID of the NFT
     */
    function transferFrom(address from, address to, uint256 id)
        public
        payable
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        _beforeTransfer(from, to, id);
        super.transferFrom(from, to, id);
    }

    /**
     *  @notice Approves an address to transfer a specific NFT. Reverts if caller is not owner or approved operator.
     *  @dev Overriden to call the beforeApprove hook. Skips calling the hook if it doesn't exist.
     *  @param spender The address to approve
     *  @param id The token ID of the NFT
     */
    function approve(address spender, uint256 id) public payable override(ERC721AUpgradeable, IERC721AUpgradeable) {
        _beforeApprove(msg.sender, spender, id, true);
        super.approve(spender, id);
    }

    /**
     *  @notice Approves or revokes approval from an operator to transfer or issue approval for all of the caller's NFTs.
     *  @param operator The address to approve or revoke approval from
     *  @param approved Whether the operator is approved
     */
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721AUpgradeable, IERC721AUpgradeable)
    {
        _beforeApproveForAll(msg.sender, operator, approved);
        super.setApprovalForAll(operator, approved);
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets contract URI
    function _setupContractURI(string memory contractURI) internal {
        _contractURI = contractURI;
        emit ContractURIUpdated();
    }

    /*//////////////////////////////////////////////////////////////
                        CALLBACK INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Calls the beforeMint hook.
    function _beforeMint(address to, uint256 quantity, bytes calldata data) internal virtual {
        _executeCallbackFunction(
            BeforeMintCallbackERC721.beforeMintERC721.selector,
            abi.encodeCall(BeforeMintCallbackERC721.beforeMintERC721, (to, quantity, data))
        );
    }

    /// @dev Calls the beforeTransfer hook, if installed.
    function _beforeTransfer(address from, address to, uint256 tokenId) internal virtual {
        _executeCallbackFunction(
            BeforeTransferCallbackERC721.beforeTransferERC721.selector,
            abi.encodeCall(BeforeTransferCallbackERC721.beforeTransferERC721, (from, to, tokenId))
        );
    }

    /// @dev Calls the beforeBurn hook, if installed.
    function _beforeBurn(address operator, uint256 tokenId, bytes calldata data) internal virtual {
        _executeCallbackFunction(
            BeforeBurnCallbackERC721.beforeBurnERC721.selector,
            abi.encodeCall(BeforeBurnCallbackERC721.beforeBurnERC721, (operator, tokenId, data))
        );
    }

    /// @dev Calls the beforeApprove hook, if installed.
    function _beforeApprove(address from, address to, uint256 tokenId, bool approved) internal virtual {
        _executeCallbackFunction(
            BeforeApproveCallbackERC721.beforeApproveERC721.selector,
            abi.encodeCall(BeforeApproveCallbackERC721.beforeApproveERC721, (from, to, tokenId, approved))
        );
    }

    /// @dev Calls the beforeApprove hook, if installed.
    function _beforeApproveForAll(address from, address to, bool approved) internal virtual {
        _executeCallbackFunction(
            BeforeApproveForAllCallback.beforeApproveForAll.selector,
            abi.encodeCall(BeforeApproveForAllCallback.beforeApproveForAll, (from, to, approved))
        );
    }

    /// @dev Fetches token URI from the token metadata hook.
    function _getTokenURI(uint256 tokenId) internal view virtual returns (string memory uri) {
        (, bytes memory returndata) = _executeCallbackFunctionView(
            OnTokenURICallback.onTokenURI.selector, abi.encodeCall(OnTokenURICallback.onTokenURI, (tokenId))
        );
        uri = abi.decode(returndata, (string));
    }
}