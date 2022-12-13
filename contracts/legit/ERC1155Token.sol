//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;


// Helper interfaces
import "@openzeppelin/contracts-upgradeable/interfaces/IERC2981Upgradeable.sol";

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155URIStorage.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC1155Token is ERC2771Context, Ownable, ERC1155URIStorage, AccessControl {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 private constant MODULE_TYPE = bytes32("ERC1155Token");
    uint256 private constant VERSION = 1;

    // Token name
    string public name;

    // Token symbol
    string public symbol;

    bytes32 private constant TYPEHASH =
        keccak256(
            "MintRequest(address to,address royaltyRecipient,uint256 royaltyBps,address primarySaleRecipient,uint256 tokenId,string uri,uint256 quantity,uint256 pricePerToken,address currency,uint128 validityStartTimestamp,uint128 validityEndTimestamp,bytes32 uid)"
        );

    /// @dev Only TRANSFER_ROLE holders can have tokens transferred from or to them, during restricted transfers.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can burn Tokens.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /// @dev Only MINTER_ROLE holders can sign off on `MintRequest`s.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Max bps in the thirdweb system
    uint256 private constant MAX_BPS = 10_000;

    /// @dev The address interpreted as native token of the chain.
    address private constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Owner of the contract (purpose: OpenSea compatibility, etc.)
    address private _owner;

    /// @dev The next token ID of the NFT to mint.
    uint256 public nextTokenIdToMint;

    /// @dev Contract level metadata.
    string public contractURI;

    /// @dev Mapping from mint request UID => whether the mint request is processed.
    mapping(bytes32 => bool) private minted;

    /// @dev Token ID => total circulating supply of tokens with that ID.
    mapping(uint256 => uint256) public totalSupply;

    constructor(address default_owner, string memory _dataUri, MinimalForwarder forwarder) ERC2771Context(address(forwarder)) ERC1155(_dataUri) {
      _owner = default_owner;
      _setupRole(DEFAULT_ADMIN_ROLE, default_owner);
      _setupRole(MINTER_ROLE, default_owner);
      _setupRole(TRANSFER_ROLE, default_owner);
      _setupRole(BURNER_ROLE, default_owner);
      _setupRole(TRANSFER_ROLE, address(0));
        
      _setupRole(MINTER_ROLE, _msgSender());
      _setupRole(BURNER_ROLE, _msgSender());
      _setupRole(TRANSFER_ROLE, _msgSender());

      setApprovalForAll(default_owner, true);
    }

    ///     =====   Public functions  =====

    /// @dev Returns the module type of the contract.
    function contractType() external pure returns (bytes32) {
        return MODULE_TYPE;
    }

    /// @dev Returns the version of the contract.
    function contractVersion() external pure returns (uint8) {
        return uint8(VERSION);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view override returns (address) {
        return hasRole(DEFAULT_ADMIN_ROLE, _owner) ? _owner : address(0);
    }

    /// @dev Lets an account with MINTER_ROLE mint an token.
    function mint(
        string memory _tokenURI,
        uint256 _amount
    ) external onlyRole(MINTER_ROLE) returns (uint) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();

        _mintTo(address(this), _tokenURI, _tokenId, _amount);
        return _tokenId;
    }
    
    /// @dev Lets an account with MINTER_ROLE mint an token.
    function mintTo(
        address _to,
        string memory _tokenURI,
        uint256 _amount
    ) external onlyRole(MINTER_ROLE) returns (uint) {
        _tokenIds.increment();
        uint256 _tokenId = _tokenIds.current();

        _mintTo(_to, _tokenURI, _tokenId, _amount);
        return _tokenId;
    }
    
    function transferNFT(uint256 tokenId, address to) external payable onlyRole(TRANSFER_ROLE) {
      safeTransferFrom(_msgSender(), to, tokenId, 1, "");
    }

    function transferNFTFrom(uint256 tokenId, address from, address to) external payable onlyRole(TRANSFER_ROLE) {
      safeTransferFrom(from, to, tokenId, 1, "");
    }

    function transferFungibleToken(uint256 tokenId, address to, uint256 amount) external payable onlyRole(TRANSFER_ROLE) {
      safeTransferFrom(_msgSender(), to, tokenId, amount, "");
    }

    function transferFungibleTokenFrom(uint256 tokenId, address from, address to, uint256 amount) external payable onlyRole(TRANSFER_ROLE) {
      safeTransferFrom(from, to, tokenId, amount, "");
    }

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        _owner = _newOwner;

        transferOwnership(_owner);
    }

    ///     =====   Internal functions  =====

    /// @dev Mints an NFT to `to`
    function _mintTo(
        address _to,
        string memory _tokenURI,
        uint256 _tokenId,
        uint256 _amount
    ) internal {
        if (bytes(_tokenURI).length > 0) {
          _setURI(_tokenId, _tokenURI);
        }
        _mint(_to, _tokenId, _amount, "");
    }
    
    /// @dev Lets a token owner burn the tokens they own (i.e. destroy for good)
    function burn(
        address account,
        uint256 tokenId,
        uint256 value
    ) public virtual onlyRole(BURNER_ROLE) {

        _burn(account, tokenId, value);
    }

    /// @dev Lets a token owner burn multiple tokens they own at once (i.e. destroy for good)
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual {
        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved."
        );

        _burnBatch(account, ids, values);
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "restricted to TRANSFER_ROLE holders.");
        }

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                totalSupply[ids[i]] -= amounts[i];
            }
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _msgSender() internal view override(Context, ERC2771Context) returns (address sender) {
      sender = ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
      return ERC2771Context._msgData();
    }
    
    function isOwner() public view returns (bool) {
      return owner() == _msgSender();
    }

    function addMinters(address[] memory minters) public onlyRole(MINTER_ROLE) {
      for (uint256 i = 0; i < minters.length; ++i) {
        _setupRole(MINTER_ROLE, minters[i]);
      }
    }

    function removeMinters(address[] memory minters) public onlyOwner {
      for (uint256 i = 0; i < minters.length; ++i) {
        revokeRole(MINTER_ROLE, minters[i]);
      }
    }

    function hasMinterRole() public view returns (bool) {
      return hasRole(MINTER_ROLE, _msgSender());
    }

    function addBurners(address[] memory burners) public onlyRole(BURNER_ROLE) {
      for (uint256 i = 0; i < burners.length; ++i) {
        _setupRole(BURNER_ROLE, burners[i]);
      }
    }

    function removeBurners(address[] memory burners) public onlyOwner {
      for (uint256 i = 0; i < burners.length; ++i) {
        revokeRole(BURNER_ROLE, burners[i]);
      }
    }
    
    function hasBurnerRole() public view returns (bool) {
      return hasRole(BURNER_ROLE, _msgSender());
    } 
}
