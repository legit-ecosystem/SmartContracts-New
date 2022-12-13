//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

//  ==========  External imports    ==========


import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ERC721Token is ERC2771Context, Ownable, ERC721URIStorage, AccessControl {

    bytes32 private constant MODULE_TYPE = bytes32("ERC721Token");
    uint256 private constant VERSION = 1;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /// @dev Only transfers to or from TRANSFER_ROLE holders are valid, when transfers are restricted.
    bytes32 private constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    /// @dev Only MINTER_ROLE holders can burn NFTs.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    /// @dev Only MINTER_ROLE holders can mint NFTs.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @dev Owner of the contract (purpose: OpenSea compatibility)
    address private _owner;

    /*///////////////////////////////////////////////////////////////
                                Mappings
    //////////////////////////////////////////////////////////////*/

    /// @dev Mapping from tokenId => price of each NFT.
    mapping(uint256 => uint256) public price;

    struct MarketItem {
      uint256 tokenId;
      address owner;
      uint256 price;
    }

    /*///////////////////////////////////////////////////////////////
                    Constructor + initializer logic
    //////////////////////////////////////////////////////////////*/

    constructor(string memory token_name, string memory token_symbol, address default_owner, MinimalForwarder forwarder) ERC2771Context(address(forwarder)) ERC721(token_name, token_symbol) {
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

    /// @dev Returns the type of the contract.
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

    function mint(string memory _tokenURI, uint256 _price) public onlyRole(MINTER_ROLE) returns (uint) {
      _tokenIds.increment();
      uint256 _tokenId = _tokenIds.current();
      price[_tokenId] = _price;
      _mint(address(this), _tokenId);
      _setTokenURI(_tokenId, _tokenURI);
      return _tokenId;
    }

    function transferNFT(uint256 _id, address to) external payable onlyRole(TRANSFER_ROLE) {
      _transfer(_msgSender(), to, _id);
    }

    function transferNFTFrom(uint256 _id, address from, address to) external payable onlyRole(TRANSFER_ROLE) {
      safeTransferFrom(from, to, _id);
    }

    function setOwner(address _newOwner) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _newOwner), "!ADMIN");
        _owner = _newOwner;

        transferOwnership(_owner);
    }

    /*///////////////////////////////////////////////////////////////
                        Miscellaneous
    //////////////////////////////////////////////////////////////*/

    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    function burn(uint256 tokenId) public virtual onlyRole(BURNER_ROLE) {
      _burn(tokenId);
    }

    /// @dev See {ERC721-_beforeTokenTransfer}.
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);

        // if transfer is restricted on the contract, we still want to allow burning and minting
        if (!hasRole(TRANSFER_ROLE, address(0)) && from != address(0) && to != address(0)) {
            require(hasRole(TRANSFER_ROLE, from) || hasRole(TRANSFER_ROLE, to), "!TRANSFER_ROLE");
        }
    }

    function fetchAllNFTs() public view returns (MarketItem[] memory) {
      uint totalItemCount = _tokenIds.current();
      uint itemCount = 0;

      for (uint tokenId = 1; tokenId <= totalItemCount; tokenId++) {
        if (_exists(tokenId)) {
          itemCount += 1;
        }
      }

      MarketItem[] memory items = new MarketItem[](itemCount);
      itemCount = 0;
      for (uint tokenId = 1; tokenId <= totalItemCount; tokenId++) {
        if (_exists(tokenId)) {
          items[itemCount] = MarketItem(
            tokenId,
            ownerOf(tokenId),
            price[tokenId]
          );
          itemCount += 1;
        }
      }
      return items;
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

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}