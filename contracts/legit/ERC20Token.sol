//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "@openzeppelin/contracts/metatx/MinimalForwarder.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract ERC20Token is ERC2771Context, Ownable, ERC20, AccessControl {
  address private _owner;

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
  bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

  constructor(string memory token_name, string memory token_code, uint _initial_amount, address owner, address[] memory minters, MinimalForwarder forwarder) ERC2771Context(address(forwarder)) ERC20(token_name, token_code)  { // owner, supply
    // uint _initial_supply = _initial_amount * (10**18);
    uint _initial_supply = _initial_amount;
    _owner = owner;
    transferOwnership(owner);
    _mint(owner, _initial_supply);
    _setupRole(DEFAULT_ADMIN_ROLE, owner);
    _setupRole(MINTER_ROLE, owner);
    _setupRole(BURNER_ROLE, owner);
    _setupRole(TRANSFER_ROLE, owner);
    
    _setupRole(MINTER_ROLE, _msgSender());
    _setupRole(BURNER_ROLE, _msgSender());
    _setupRole(TRANSFER_ROLE, _msgSender());

    for (uint256 i = 0; i < minters.length; ++i) {
      grantRole(MINTER_ROLE, minters[i]);
    }
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
// onlyRole(MINTER_ROLE)
  function addMinters(address[] memory minters) public  {
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
// onlyRole(MINTER_ROLE)
  function mint(uint256 amount) public {
    _mint(_msgSender(), amount);
    _mint(msg.sender, amount);
  }
  
  function burn(address from, uint256 amount) public onlyRole(BURNER_ROLE) {
    _burn(from, amount);
  }

  function transferFrom(
      address from,
      address to,
      uint256 amount
  ) public onlyRole(TRANSFER_ROLE) virtual override returns (bool) {
      // address spender = _msgSender();
      // require(spender == owner, "Error: transfer not allowed from this address");
      _transfer(from, to, amount);
      return true;
  }
}
