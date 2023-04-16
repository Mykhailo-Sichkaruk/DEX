// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./token.sol";
import "hardhat/console.sol";

// REVIEW: exchange_rate !

contract TokenExchange is Ownable {
    /**
     * @notice Rate is ratio of token / shares to rate_denominator ETHs 
     * token_to_eth = rate_denominator * token_reserves / eth_reserves
     */
    uint private constant rate_denominator = 1000;
    uint private constant precision = 10000; 
    string public exchange_name = "OldyChange";

    address tokenAddr = 0x5FbDB2315678afecb367f032d93F642f64180aa3;
    Token public token = Token(tokenAddr);

    // Liquidity pool for the exchange
    uint private total_shares = 0;
    uint private total_fees = 0;

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
        // require nonzero values were sent
        require(msg.value > 0, "Need eth to create pool.");
        uint tokenSupply = token.balanceOf(msg.sender);
        require(
            amountTokens <= tokenSupply,
            "Not have enough tokens to create the pool"
        );
        require(amountTokens > 0, "Need tokens to create pool.");

        token.transferFrom(msg.sender, address(this), amountTokens);
        k = token.balanceOf(address(this)) * address(this).balance;

        total_shares = address(this).balance;
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

    function getRateDenominator() public pure returns (uint) {
        return rate_denominator;
    }

    // ============================================================
    //                    FUNCTIONS TO IMPLEMENT
    // ============================================================

    /* ========================= Liquidity Provider Functions =========================  */

    // Function addLiquidity: Adds liquidity given a supply of ETH (sent to the contract as msg.value).
    // You can change the inputs, or the scope of your function, as needed.
    function addLiquidity(
        uint min_token_rate,
        uint max_token_rate
    ) external payable {
        /******* TODO: Implement this function *******/
        uint shares_rate = (rate_denominator * total_shares) / (address(this).balance - msg.value);
        uint tokens_rate = (rate_denominator * token.balanceOf(address(this))) / (address(this).balance - msg.value);
        require(
            tokens_rate <= max_token_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            tokens_rate >= min_token_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(msg.value > 0, "ETH value should be larger than 0");

        // Amount of tokens client need to pay
        uint tokens_to_add = (msg.value * tokens_rate) / rate_denominator;
        console.log("tokens_to_add", tokens_to_add);
        // Find shares for client
        uint shares_to_add = (msg.value * shares_rate) / rate_denominator;
        console.log("shares_to_add", shares_to_add);
        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            msg.sender,
            address(this),
            tokens_to_add
        );
        require(is_transfer_successfull, "Cound not transfer tokens");

        // Add shares to client
        lps[msg.sender] += shares_to_add;
        total_shares += shares_to_add;

        k = token.balanceOf(address(this)) * address(this).balance;
    }

    // Function removeLiquidity: Removes liquidity given the desired amount of ETH to remove.
    // You can change the inputs, or the scope of your function, as needed.
    function removeLiquidity(
        uint amountETH,
        uint min_exchange_rate,
        uint max_exchange_rate
    ) public payable {
        uint shares_rate = (rate_denominator * total_shares) / (address(this).balance - msg.value);
        uint tokens_rate = (rate_denominator * token.balanceOf(address(this))) / (address(this).balance - msg.value);
        require(
            tokens_rate <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            tokens_rate >= min_exchange_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(amountETH > 0, "ETH value should be larger than 0");
        // Amount of tokens client we return
        uint tokens_to_return = (msg.value * tokens_rate) / rate_denominator;
        // Find shares for client
        uint shares_to_remove = (msg.value * shares_rate) / rate_denominator;
        // Transfer tokens to client
        bool is_transfer_successfull = token.transferFrom(
            address(this),
            msg.sender,
            tokens_to_return
        );
        require(is_transfer_successfull, "Cound not transfer tokens to client");

        payable(msg.sender).transfer(amountETH); 
        // Remove shares from client
        lps[msg.sender] -= shares_to_remove;
        total_shares -= shares_to_remove;
        k = token.balanceOf(address(this)) * address(this).balance;
        console.log("token balance", token.balanceOf(address(this)));
        console.log("eth balance", address(this).balance);  
    }

    // Function removeAllLiquidity: Removes all liquidity that msg.sender is entitled to withdraw
    // You can change the inputs, or the scope of your function, as needed.
    function removeAllLiquidity(
        uint min_exchange_rate,
        uint max_exchange_rate
    ) public payable {
        uint eth_shares_rate = (rate_denominator * address(this).balance) / total_shares;
        uint tokens_rate = (rate_denominator * token.balanceOf(address(this))) / address(this).balance;
        console.log("tokens_rate", tokens_rate);
        require(
            tokens_rate <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        require(
            tokens_rate >= min_exchange_rate,
            "Exchange rate is smaller than min exchange rate"
        );
        require(lps[msg.sender] > 0, "You don't have any liquidity");
        console.log("min_exchange_rate", min_exchange_rate);
        console.log("max_exchange_rate", max_exchange_rate);
        uint amountETH = ((lps[msg.sender] * eth_shares_rate * precision) / rate_denominator) / precision;
        console.log("Current shares balance", lps[msg.sender]);
        console.log("total_shares", total_shares);
        require(amountETH > 0, "ETH value should be larger than 0");
        // Amount of tokens client we return
        uint tokens_to_return = (amountETH * tokens_rate) / rate_denominator;
        console.log("tokens_to_return", tokens_to_return);
        console.log("amountETH", amountETH);
        console.log("shares_rate", eth_shares_rate);
        // Find shares for client
        // Transfer tokens to client
        bool is_transfer_successfull = token.transfer(
            msg.sender,
            tokens_to_return
        );
        require(is_transfer_successfull, "Cound not transfer tokens to client");

        payable(msg.sender).transfer(amountETH); 
        console.log("token balance", token.balanceOf(address(this)));
        console.log("eth balance", address(this).balance);  
        // Remove shares from client
        // lps[msg.sender] -= shares_to_remove;
        total_shares -= lps[msg.sender];
        lps[msg.sender] = 0;
        k = token.balanceOf(address(this)) * address(this).balance;
    }

    /***  Define additional functions for liquidity fees here as needed ***/

    /* ========================= Swap Functions =========================  */

    // Function swapTokensForETH: Swaps your token with ETH
    // You can change the inputs, or the scope of your function, as needed.
    function swapTokensForETH(
        uint amountTokens,
        uint max_exchange_rate
    ) external payable {
        uint real_tokens = (amountTokens * (swap_fee_denominator - swap_fee_numerator)) / swap_fee_denominator;
        uint token_rate = (rate_denominator * token.balanceOf(address(this))) / address(this).balance; 
        require(
            token_rate <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );

        // Transfer tokens to exchange sol
        bool is_transfer_successfull = token.transferFrom(
            msg.sender,
            address(this),
            amountTokens
        );
        require(is_transfer_successfull, "Token transfer failed");

        uint new_token_reserves_without_fee = (token.balanceOf(address(this)) - amountTokens) + real_tokens;
        uint new_eth_reserves = precision * k / new_token_reserves_without_fee;
        uint eth_to_swap = ((address(this).balance * precision) - new_eth_reserves) / precision;
        payable(msg.sender).transfer(eth_to_swap);
    }

    // Function swapETHForTokens: Swaps ETH for your tokens
    // ETH is sent to contract as msg.value
    // You can change the inputs, or the scope of your function, as needed.
    function swapETHForTokens(uint max_exchange_rate) external payable {
        /******* TODO: Implement this function *******/
        require(msg.value > 0, "ETH value should be larger than 0");
        uint token_rate = (rate_denominator * (token.balanceOf(address(this)))) / (address(this).balance - msg.value);
        require(
            token_rate <= max_exchange_rate,
            "Exchange rate is larger than max exchange rate"
        );
        // Find fee
        uint real_eth = (msg.value * (swap_fee_denominator - swap_fee_numerator)) / swap_fee_denominator;
        console.log("real_eth", real_eth);
        // Update eth pool
        uint eth_reserves_without_fee = address(this).balance - msg.value + real_eth;
        console.log("eth_reserves_without_fee", eth_reserves_without_fee);
        uint new_token_reserves = (precision * k) / eth_reserves_without_fee;
        console.log("new_token_reserves", new_token_reserves);
        uint token_to_swap = ((token.balanceOf(address(this)) * precision) - new_token_reserves) / precision;
        console.log("token_to_swap", token_to_swap);

        // Transfer tokens to client
        bool is_transfer_successfull = token.transfer(
            msg.sender,
            token_to_swap
        );
        require(is_transfer_successfull, "Transfer failed");
    }
}
