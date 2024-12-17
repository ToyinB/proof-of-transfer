# Proof of Transfer (PoT) Smart Contract

## Overview
This Clarity smart contract provides a secure and flexible mechanism for transferring STX tokens with built-in confirmation, cancellation, and fee management features.

## Features
- Secure token transfers with confirmation process
- Transfer fee mechanism
- Cancellation of unconfirmed transfers
- Flexible fee and collector address management

## Contract Functions

### Transfer Initiation
`initiate-transfer(recipient, amount)`
- Starts a new transfer
- Checks sender's balance
- Collects transfer fee
- Generates unique transfer ID

### Transfer Confirmation
`confirm-transfer(sender, recipient, transfer-id)`
- Allows recipient to complete the transfer
- Prevents double-spending
- Transfers tokens to recipient

### Transfer Cancellation
`cancel-transfer(recipient, transfer-id)`
- Enables sender to cancel unconfirmed transfers
- Refunds transfer fee
- Prevents cancellation of confirmed transfers

## Error Handling
- Comprehensive error codes for different scenarios
- Validation checks at each transfer stage

## Usage Example
```clarity
;; Initiate a transfer of 100 STX to a recipient
(initiate-transfer 'ST2CY5V39MWMZX6MWJW4P8BQDHVTD5BWPWSQ9QR7 u100)

;; Confirm the transfer
(confirm-transfer 'ST1HTBVD3FMWKWMTN1SPZQPMFPJWFNQF4PCSJQW3E 'ST2CY5V39MWMZX6MWJW4P8BQDHVTD5BWPWSQ9QR7 u0)
```

## Fee Management
- Default transfer fee: 10 STX
- Fee collector can update transfer fees
- Fee collector address can be changed

## Security Considerations
- Validates sender balance before transfer
- Prevents unauthorized transfer confirmations
- Implements multiple validation checkpoints

## Contract Deployment
Deploy on Stacks blockchain using a Clarity-compatible wallet or deployment tool.
