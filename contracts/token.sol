// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// Your token contract
contract Token is Ownable, ERC20 {
    uint32 constant OLDY_CENT = 1;
    uint32 private constant OLDY_DECIMALS = 3;
    uint32 constant OLDY_DECIMAL_MULTIPLIER = uint32(10 ** OLDY_DECIMALS);
    uint32 constant OLDY_COIN = OLDY_DECIMAL_MULTIPLIER * OLDY_CENT;
    uint32 constant OLDY_TOTAL_SUPPLY = 10000 * OLDY_COIN;

    string private constant _symbol = "OLDY"; // TODO: Give your token a symbol (all caps!)
    string private constant _name = "Oldwave"; // TODO: Give your token a name
    bool public mintingDisabled = false;

    constructor() ERC20(_name, _symbol) {}

    modifier restricted(uint amount) {
        require(amount >= 0, "Amount should be greater than 0");
        require(amount + totalSupply() < OLDY_TOTAL_SUPPLY, "No more token");
        require(!mintingDisabled, "minting disabled");
        _;
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================
    // Function _mint: Create more of your tokens.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!
    function mint(uint amount) public onlyOwner restricted(amount) {
        _mint(msg.sender, amount);
    }

    // Function _disable_mint: Disable future minting of your token.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!
    function disable_mint() public onlyOwner {
        mintingDisabled = true;
    }
}
