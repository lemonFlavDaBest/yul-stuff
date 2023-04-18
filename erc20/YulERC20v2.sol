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
bytes32 constant transferHash = 0xa9059cbb2ab09eb219583f4a59a5d0623ade346d962bcd4e46b11da047c9049b;

error InsufficientBalance();
error InsufficientAllowance(address owner, address spender);

/// @title Yul ERC20
/// @author lemonflavdabest
/// @notice For demo purposes ONLY.

//mstore() first value is the slot, and the second value is what you want to store there
contract YulERC20v2 {

    event Transfer(address indexed sender, address indexed receiver, uint256 amount);

    // owner --> balance
    mapping (address => uint256) internal _balances;

    // owner -- > spender --> amount allowed
    //keccak256(spender, keccak256(owner, slot))
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

    // this is the un optimized version. slower but easier to read
    /*
    function balanceOf(address) public view returns (uint256) {
        assembly {
            //first 4bytes of calldata are funcsig
            // the next bytes are the function arg. so we have an index of 4
            let account := calldataload(4)

            mstore(0x00, account)
            mstore(0x20, 0x00)

            let hash := keccak256(0x0, 0x40)
            let accountBalance := sload(hash)

            mstore(0x00, accountBalance)
            return (0x00, 0x20)
        }
    }
    */

   function balanceOf(address) public view returns (uint256) {
        assembly {
            mstore(0x00, calldataload(4))
            mstore(0x20, 0x00)
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            return (0x00, 0x20)
        }
   }

    //this transfer function is unoptimized
   function transfer(address receiver, uint256 value) public returns (bool) {
        assembly{
            let memptr := mload(0x40)
            mstore(memptr, caller())
            mstore(add(memptr, 0x20), 0x00)
            //i might need a refresher on why the 0x40 on the next line
            let callerBalanceSlot := keccak256(memptr, 0x40)
            let callerBalance := sload(callerBalanceSlot)

            if lt(callerBalance, value) {
                mstore(0x00, insufficientBalanceSelector)
                revert(0x00, 0x04)
            }

    /* this was a late catch, so this is not actually the correct way to implement
            if eq(caller(), receiver) {
                revert(0x00, 0x00)
            }
    */

            let newCallerBalance := sub(callerBalance, value)
            //again, we can overwrite these slots because we will not need the old ones
            mstore(memptr, receiver)
            mstore(add(memptr, 0x20), 0x00)

            let receiverBalanceSlot := keccak256(memptr,0x40)
            let receiverBalance := sload(receiverBalanceSlot)
            
            let newReceiverBalance := add(receiverBalance, value)

            //storage
            sstore(callerBalanceSlot, newCallerBalance)
            sstore(receiverBalanceSlot, newReceiverBalance)

            //logging for events
            mstore(0x00, value)
            log3(0x00, 0x20, transferHash, caller(), receiver)

            mstore(0x00, 0x01)
            return(0x00, 0x20)
        }
   }

   function allowance (address owner, address spender) public view returns (uint256) {
        assembly {
            mstore(0x00, caller())
            mstore(0x20, 0x01)
            let innerHash := keccak256(0x00, 0x40)

            mstore(0x00, spender)
            mstore(0x20, innerHash)
            let allowanceSlot := keccak256(0x00, 0x40)

            let allowanceValue := sload(allowanceSlot)

            mstore(0x00, allowanceValue)

            return (0x00, 0x20)
        }
   }

   function approve (address spender, uint256 amount) public returns (bool) {
        
   }
}