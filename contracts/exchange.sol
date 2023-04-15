// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token.sol";
import "hardhat/console.sol";

// REVIEW: exchange_rate !

contract TokenExchange is Ownable {
    string public exchange_name = "OldyChange";

    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    Token public token = Token(tokenAddr);

    // Liquidity pool for the exchange
    uint private token_reserves = 0;
    uint private eth_reserves = 0;
    uint private total_shares = 0;
    uint private total_fees = 0;
    uint private constant BASIC_FEE = 3;

    mapping(address => uint) private lps;

    // Needed for looping through the keys of the lps mapping
    address[] private lp_providers;
    // liquidity rewards
    uint private swap_fee_numerator = 3;
    uint private swap_fee_denominator = 100;

    // Constant: x * y = k
    uint private k;

    constructor() {}

    // Function createPool: Initializes a liquidity pool between your Token and ETH.
    // ETH will be sent to pool in this transaction as msg.value
    // amountTokens specifies the amount of tokens to transfer from the liquidity provider.
    // Sets up the initial exchange rate for the pool by setting amount of token and amount of ETH.
    function createPool(uint amountTokens) external payable onlyOwner {
        // This function is already implemented for you; no changes needed.

        // require pool does not yet exist:
        require(token_reserves == 0, "Token reserves was not 0");
        require(eth_reserves == 0, "ETH reserves was not 0.");

        // require nonzero values were sent
        require(msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(
            amountTokens <= tokenSupply,
            "Not have enough tokens to create the pool"
        );
        require(amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        token_reserves = token.balanceOf(address(this));
        eth_reserves = msg.value;
        k = token_reserves * eth_reserves;

        total_shares = eth_reserves;
        lps[msg.sender] = msg.value;
    }

    // Function removeLP: removes a liquidity provider from the list.
    // This function also removes the gap left over from simply running "delete".
    function removeLP(uint index) private {
        require(
            index < lp_providers.length,
            "specified index is larger than the number of lps"
        );
        lp_providers[index] = lp_providers[lp_providers.length - 1];
        lp_providers.pop();
    }

    // Function getSwapFee: Returns the current swap fee ratio to the client.
    function getSwapFee() public view returns (uint, uint) {
        return (swap_fee_numerator, swap_fee_denominator);
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================

    /* ========================= Liquidity Provider Functions =========================  */

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(
        uint max_exchange_rate,
        uint min_exchange_rate
    ) external payable {
        /******* TODO: Implement this function *******/
        uint shares_to_eth = total_shares / eth_reserves;
        uint token_to_eth = token_reserves / eth_reserves;
        require(
            token_to_eth <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            token_to_eth >= min_exchange_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(msg.value > 0, "ETH value should be larger than 0");

        // Amount of tokens client need to pay
        uint token_to_add = msg.value * token_to_eth;
        // Find shares for client
        uint shares_to_add = msg.value * shares_to_eth;

        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            msg.sender,
            address(this),
            token_to_add
        );
        require(is_transfer_successfull, "Cound not transfer tokens");

        // Add shares to client
        lps[msg.sender] += shares_to_add;

        total_shares += shares_to_add;
        eth_reserves += msg.value;
        token_reserves += token_to_add;

        k = token_reserves * eth_reserves;
    }

    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(
        uint amountETH,
        uint max_exchange_rate,
        uint min_exchange_rate
    ) public payable {
        uint shares_to_eth = total_shares / eth_reserves;
        uint token_to_eth = token_reserves / eth_reserves;
        require(
            token_to_eth <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            token_to_eth >= min_exchange_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(amountETH > 0, "ETH value should be larger than 0");

        // Amount of tokens client we return
        uint token_to_return = msg.value * token_to_eth;
        // Find shares for client
        uint shares_to_remove = msg.value * shares_to_eth;

        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            address(this),
            msg.sender,
            token_to_return
        );
        require(is_transfer_successfull, "Cound not transfer tokens to client");

        payable(msg.sender).transfer(amountETH); // HACK: require needed ?

        // Remove shares from client
        lps[msg.sender] -= shares_to_remove;

        total_shares -= shares_to_remove;
        eth_reserves -= msg.value;
        token_reserves -= token_to_return;

        k = token_reserves * eth_reserves;
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(
        uint max_exchange_rate,
        uint min_exchange_rate
    ) external payable {
        /******* TODO: Implement this function *******/
        uint eth_to_shares = eth_reserves / total_shares;
        uint token_to_eth = token_reserves / eth_reserves;
        require(
            token_to_eth <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            token_to_eth >= min_exchange_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(lps[msg.sender] > 0, "You don't have any liquidity");
        uint amountETH = lps[msg.sender] * eth_to_shares;
        removeLiquidity(amountETH, max_exchange_rate, min_exchange_rate);
    }

    /***  Define additional functions for liquidity fees here as needed ***/

    /* ========================= Swap Functions =========================  */

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(
        uint amountTokens,
        uint max_exchange_rate
    ) external payable {
        /******* TODO: Implement this function *******/
        // Check if client have enough tokens
        require(
            token.balanceOf(msg.sender) >= amountTokens,
            "Client doesn't have enough tokens"
        );
        uint token_to_eth = token_reserves / eth_reserves;
        require(
            token_to_eth <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );

        uint fee = (amountTokens * (1000 - BASIC_FEE)) / 1000;
        // New amount of tockens that will be swapped
        amountTokens = amountTokens - fee; // REVIEW: + / - fee

        // Put fee into fees array
        total_fees += fee;

        // Update token pool
        token_reserves = token_reserves + amountTokens;

        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            msg.sender,
            address(this),
            amountTokens
        );
        require(is_transfer_successfull, "Transfer failed");

        uint new_eth_reserves = k / token_reserves;
        uint eth_to_swap = new_eth_reserves - eth_reserves;
        eth_reserves = new_eth_reserves;
        payable(msg.sender).transfer(eth_to_swap);
    }

    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate) external payable {
        /******* TODO: Implement this function *******/
        require(msg.value > 0, "ETH value should be larger than 0");
        uint token_to_eth = token_reserves / eth_reserves;
        require(
            token_to_eth <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );

        // Update eth pool
        uint new_eth_reserves = eth_reserves + msg.value;
        uint token_to_swap = k / new_eth_reserves;
        token_reserves = token_reserves - token_to_swap;
        eth_reserves = new_eth_reserves;

        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            address(this),
            msg.sender,
            token_to_swap
        );
        require(is_transfer_successfull, "Transfer failed");
    }
}
