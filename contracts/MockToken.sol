// Current Version of solidity
pragma solidity =0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Main coin information
contract MockToken is ERC20 {
    constructor() ERC20("MockToken", "MT") {
        _mint(msg.sender, 100000000000000000000000000);
    }

    function mint() public {
        _mint(msg.sender, 100000000000000000000000000);
    }
}
