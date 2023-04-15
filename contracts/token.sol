// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 
// Your token contract
contract Token is Ownable, ERC20 {
    uint32 private constant _TSCT_cent = 1;
    uint32 private constant _TSTC_DECIMALS = 3;
    uint32 private constant _TSTC_DECIMAL_MULTIPLIER = uint32(10 ** _TSTC_DECIMALS);
    uint32 private constant _TSCT_coin = _TSTC_DECIMAL_MULTIPLIER * _TSCT_cent;
    uint32 private constant _TSCT_TOTAL_SUPPLY = 1000 * _TSCT_coin;
    string private constant _symbol = 'O_W';                 // TODO: Give your token a symbol (all caps!)
    string private constant _name = 'Oldwave';               // TODO: Give your token a name
    bool private _disable_minting = false;


    constructor() ERC20(_name, _symbol) {}

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================

    modifier notDisabled(uint amount) {
        require(!_disable_minting, "Mint is disabled");
        require(amount >= 0, "Less than zero");
        require(
            amount + totalSupply() < _TSCT_TOTAL_SUPPLY, "Sorry, we out of tockens"
        );
        _;
    }

    // Function _mint: Create more of your tokens.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!

    function mint(uint amount) public onlyOwner notDisabled(amount) {
        /******* TODO: Implement this function *******/
        _mint(msg.sender, amount);
    }

    // Function _disable_mint: Disable future minting of your token.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!
    function disable_mint() public onlyOwner {
        /******* TODO: Implement this function *******/
        _disable_minting = true;
    }
}