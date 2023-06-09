// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Used in the `name()` function
// "Yul Token"
bytes32 constant nameLength = 0x0000000000000000000000000000000000000000000000000000000000000009;
bytes32 constant nameData = 0x59756c20546f6b656e0000000000000000000000000000000000000000000000;

// Used in the `symbol()` function
// "YUL"
bytes32 constant symbolLength = 0x0000000000000000000000000000000000000000000000000000000000000003;
bytes32 constant symbolData = 0x59554c0000000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientBalance()"))`
bytes32 constant insufficientBalanceSelector = 0xf4d678b800000000000000000000000000000000000000000000000000000000;

// `bytes4(keccak256("InsufficientAllowance(address,address)"))`
bytes32 constant insufficientAllowanceSelector = 0xf180d8f900000000000000000000000000000000000000000000000000000000;

// max uint256 value, used to mint EVERYTHING to the deployer lol
uint256 constant maxUint256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

error InsufficientBalance();
error InsufficientAllowance(address owner, address spender);

// `keccak256("Transfer(address,address,uint256)")`
bytes32 constant transferHash = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

// `keccak256("Approval(address,address,uint256)")`
bytes32 constant approvalHash = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

/// @title Yul ERC20
/// @author <your name here>
/// @notice For demo purposes ONLY.
/// @dev Some optimizations and best practices omitted here for the sake of demonstration.
contract YulERC20 {
    event Transfer(address indexed sender, address indexed receiver, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // account -> balance
    // `slot = keccak(account, 0x00))`
    mapping(address => uint256) internal _balances;

    // owner -> spender -> allowance
    // `slot = keccak256(owner, keccak256(spender, 0x01))`
    mapping(address => mapping(address => uint256)) internal _allowances;

    // `slot = 0x02`
    uint256 internal _totalSupply;

    // Mint maxUint256 tokens to the `msg.sender`.
    constructor() {
        assembly {
            // store the caller address at memory index zero
            mstore(0x00, caller())

            // store zero (storage index) at memory index 32
            mstore(0x20, 0x00)

            // hash the first 64 bytes of memory to generate the balance slot
            let slot := keccak256(0x00, 0x40)

            // store maxUint256 as caller's balance
            sstore(slot, maxUint256)

            // store maxUint256 as total supply
            sstore(0x02, maxUint256)

            // store maxUint256 in memory to log
            mstore(0x00, maxUint256)

            // log transfer event
            log3(0x00, 0x20, transferHash, 0x00, caller())
        }
    }

    function name() public pure returns (string memory) {
        assembly {
            // get free memory pointer from memory index `0x40`
            let memptr := mload(0x40)

            // store string pointer (0x20) in memory
            mstore(memptr, 0x20)
            
            // store string length in memory 32 bytes after the pointer
            mstore(add(memptr, 0x20), nameLength)
            
            // store string data 32 bytes after the length
            mstore(add(memptr, 0x40), nameData)
            
            // return from memory the three 32 byte slots (ptr, len, data)
            return(memptr, 0x60)
        }
    }

    function symbol() public pure returns (string memory) {
        assembly {
            // get free memory pointer from memory index `0x40`
            let memptr := mload(0x40)

            // store string pointer (0x20) in memory
            mstore(memptr, 0x20)
            
            // store string length in memory 32 bytes after the pointer
            mstore(add(memptr, 0x20), symbolLength)
            
            // store string data 32 bytes after the length
            mstore(add(memptr, 0x40), symbolData)
            
            // return from memory the three 32 byte slots (ptr, len, data)
            return(memptr, 0x60)
        }
    }

    function decimals() public pure returns (uint8) {
        assembly {
            // store `18` in memory at slot zero
            mstore(0, 18)

            // return 32 bytes from memory at slot zero
            return(0x00, 0x20)
        }
    }

    function totalSupply() public view returns (uint256) {
        assembly {
            // load the total supply from storage slot 0x02 and store in memory
            mstore(0x00, sload(0x02))

            // return 32 bytes from memory at index zero
            return(0x00, 0x20)
        }
    }

    function balanceOf(address) public view returns (uint256) {
        assembly {
            // load calldata offset 4 (first arg after selector) and store in memory at index zero
            mstore(0x00, calldataload(4))

            // store zero (storage index) at memory index 32
            mstore(0x20, 0x00)

            // load from storage the hash of the first 64 bytes of memory,
            // then store the value in memory at offset zero
            mstore(0x00, sload(keccak256(0x00, 0x40)))
            
            // return the first 32 bytes from memory (loaded balance)
            return(0x00, 0x20)
        }
    }

    function transfer(address receiver, uint256 amount) public returns (bool) {
        assembly {
            // load free memory pointer from index 64
            let memptr := mload(0x40)

            // store the caller address at the free memory pointer
            mstore(memptr, caller())

            // store zero (storage index) in the next memory index
            mstore(add(memptr, 0x20), 0x00)

            // hash 64 bytes of memory to generate the caller's balance slot
            let callerBalanceSlot := keccak256(memptr, 0x40)

            // load the caller's balance
            let callerBalance := sload(callerBalanceSlot)

            // if the caller's balance is less than the amount
            if lt(callerBalance, amount) {
                // store the insufficient balance selector in memory at slot zero
                mstore(0x00, insufficientBalanceSelector)

                // revert with the 4 byte selector from memory
                revert(0x00, 0x04)
            }

            // if the caller == receiver, revert
            if eq(caller(), receiver) {
                // we should have a better error message here,
                // but we were short on time
                revert(0x00, 0x00)
            }

            // decrease the caller's balance
            let newCallerBalance := sub(callerBalance, amount)

            // store the caller's balance in its slot
            sstore(callerBalanceSlot, newCallerBalance)

            // store the receiver address in memory at the memory pointer
            // (overwrites some of the memory we have written to, but we don't need it anymore)
            mstore(memptr, receiver)

            // store zero (storage index) at a 32 byte offset
            mstore(add(memptr, 0x20), 0x00)

            // hash 64 bytes of memory to generate the receiver's balance slot
            let receiverBalanceSlot := keccak256(memptr, 0x40)

            // load the receiver's balance
            let receiverBalance := sload(receiverBalanceSlot)

            // increase receiver balance
            let newReceiverBalance := add(receiverBalance, amount)

            // store the receiver's balance
            sstore(receiverBalanceSlot, newReceiverBalance)

            // store the amount in memory to be logged
            mstore(0x00, amount)

            // log the transfer event
            log3(0x00, 0x20, transferHash, caller(), receiver)

            // store `true` in memory at index zero
            mstore(0x00, 0x01)

            // return the first 32 byte word of memory
            return(0x00, 0x20)
        }
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        assembly {
            // store owner address at memory index zero
            mstore(0x00, owner)

            // store one (storage index) at memory index 32
            mstore(0x20, 0x01)

            // hash the first 64 bytes of memory to generate the inner hash
            let innerHash := keccak256(0x00, 0x40)

            // store the spender address at memory index zero
            mstore(0x00, spender)

            // store the inner hash at memory index 32
            mstore(0x20, innerHash)

            // hash the first 64 bytes of memory to generate the allowance slot
            let allowanceSlot := keccak256(0x00, 0x40)

            // load the allowance from storage
            let allowanceAmount := sload(allowanceSlot)

            // store the allowance at memory index zero
            mstore(0x00, allowanceAmount)

            // return the first 32 byte word from memory
            return(0x00, 0x20)
        }
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        assembly {
            // store the caller address
            mstore(0x00, caller())

            // store one (storage index) at memory index 32
            mstore(0x20, 0x01)

            // hash the first 64 bytes of memory to generate the inner hash
            let innerHash := keccak256(0x00, 0x40)

            // store the spender address at memory index zero
            mstore(0x00, spender)

            // store the inner hash at memory index 32
            mstore(0x20, innerHash)

            // hash the first 64 bytes of memory to generate the allowance slot
            let allowanceSlot := keccak256(0x00, 0x40)

            // store the new allowance in the allowance slot
            sstore(allowanceSlot, amount)

            // store the amount at memory index zero to be logged
            mstore(0x00, amount)

            // log the approval event
            log3(0x00, 0x20, approvalHash, caller(), spender)

            // store `true` at memory index zero
            mstore(0x00, 0x01)

            // return the first 32 byte word from memory
            return(0x00, 0x20)
        }
    }
    
    function transferFrom(address sender, address receiver, uint256 amount) public returns (bool) {
        assembly {
            // load the free memory pointer from memory index 64
            let memptr := mload(0x40)

            // store the sender address at memory index zero
            mstore(0x00, sender)

            // store one (storage index) at memory index 32
            mstore(0x20, 0x01)

            // hash the first 64 bytes of memory to generate the inner hash
            let innerHash := keccak256(0x00, 0x40)

            // store the caller (spender) at memory index zero
            mstore(0x00, caller())

            // store the inner hash at memory index 32
            mstore(0x20, innerHash)

            // hash the first 64 bytes of memory to generate the allowance slot
            let allowanceSlot := keccak256(0x00, 0x40)

            // load the caller's allowance to spend on behalf of the sender
            let callerAllowance := sload(allowanceSlot)


            // if the caller's allowance is less than the amount
            if lt(callerAllowance, amount) {

                // store the insufficient allowance error selector at the free memory pointer
                mstore(memptr, insufficientAllowanceSelector)

                // store the sender in memory after the four byte selector
                mstore(add(memptr, 0x04), sender)

                // store the caller in memory after the sender
                mstore(add(memptr, 0x24), caller())

                // revert with 68 (4 + 32 + 32) bytes of memory
                revert(memptr, 0x44)
            }


            // if the caller allowance is less than the max uint256 value (infinite)
            if lt(callerAllowance, maxUint256) {
                // subtract the amount from the allowance and store it in storage
                sstore(allowanceSlot, sub(callerAllowance, amount))
            }

            // store the sender address in memory at the free memory pointer
            mstore(memptr, sender)

            // store zero (storage index) after the sender address 
            mstore(add(memptr, 0x20), 0x00)

            // hash 64 bytes of memory starting at the free memory pointer to generate the balance slot
            let senderBalanceSlot := keccak256(memptr, 0x40)

            // load the sender balance
            let senderBalance := sload(senderBalanceSlot)


            // if the sender balance is less than the amount
            if lt(senderBalance, amount) {
                // store the insufficient balance selector in memory
                mstore(0x00, insufficientBalanceSelector)

                // revert with the error selector
                revert(0x00, 0x04)
            }


            // subtract the amount from the sender balance and store it
            sstore(senderBalanceSlot, sub(senderBalance, amount))

            // store the receiver address in memory at the free memory pointer
            mstore(memptr, receiver)

            // store zero (storage index) after the receiver address 
            mstore(add(memptr, 0x20), 0x00)

            // hash 64 bytes of memory starting at the free memory pointer to generate the balance slot
            let receiverBalanceSlot := keccak256(memptr, 0x40)

            // load the sender balance
            let receiverBalance := sload(receiverBalanceSlot)

            // add the amount and the receiver balance and store it
            sstore(receiverBalanceSlot, add(receiverBalance, amount))

            // store the amount in memory to be logged
            mstore(0x00, amount)

            // log the transfer event
            log3(0x00, 0x20, transferHash, sender, receiver)


            // store `true` in memory at slot zero
            mstore(0x00, 0x01)

            // return the first 32 byte word from memory
            return(0x00, 0x20)
        }
    }
}