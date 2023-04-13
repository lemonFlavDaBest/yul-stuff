// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Used in the `name()` function
bytes32 constant nameLength = 0x0000000000000000000000000000000000000000000000000000000000000009;
bytes32 constant nameData = 0x59756c20546f6b656e0000000000000000000000000000000000000000000000;

// Used in the `symbol()` function
bytes32 constant symbolLength = 0x0000000000000000000000000000000000000000000000000000000000000003;
bytes32 constant symbolData = 0x59554c0000000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientBalance()"))`
bytes32 constant insufficientBalanceSelector = 0xf4d678b800000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientAllowance(address,address)"))`
bytes32 constant insufficientAllowanceSelector = 0xf180d8f900000000000000000000000000000000000000000000000000000000;

error InsufficientBalance();
error InsufficientAllowance(address owner, address spender);

/// @title Yul ERC20
/// @author <your name here>
/// @notice For demo purposes ONLY.
contract YulERC20v2 {

    mapping (address => uint256) internal _balances;
    mapping (address => mapping(address => uint256)) internal _allowances;
    function name() public pure returns (string memory){
        assembly{
            let memptr := mload(0x40)
            mstore(memptr, 0x20)
            mstore(add(memptr,0x20), nameLength)
            mstore(add(memptr,0x40), nameData)
            return (memptr, 0x60)
        }
    }

    function symbol() public pure returns (string memory) {
        assembly{
            let memptr := mload(0x40)
            mstore(memptr, 0x40)
            mstore(add(memptr, 0x20), symbolLength)
            mstore(add(memptr, 0x40), symbolData)
            return(memptr, 0x60)
        }
    }

    function decimals() public pure returns (uint8) {
        assembly{
            mstore(0, 18)
            return (0x00, 0x20)
        }
    }

    function balanceOf(address) public view returns (uint256) {
        assembly {
            
        }
    }
}