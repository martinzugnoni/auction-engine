pragma solidity ^0.4.2;

import "./ERC20.sol";


contract MZToken is ERC20 {
    string public constant name = "Martin Zugnoni Token";
    string public constant symbol = "MZT";
    uint8 public constant decimals = 18;
    uint256 public constant _totalSupply = 1000 * (10**6);  // 1 billion

    address private owner;

    function MZToken() public {
        owner = msg.sender;

        // creator of the Token owns all tokens
        balances[owner] = totalSupply();
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
}
