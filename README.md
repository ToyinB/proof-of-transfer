# Proof of Transfer Smart Contract

A secure Clarity smart contract that enables safe STX transfers with confirmation mechanisms, built-in fee collection, and comprehensive validation.

## Overview

This contract implements a two-phase transfer system where transfers must be initiated by the sender and confirmed by the recipient before completion. This provides an additional layer of security and prevents unauthorized transfers.

## Features

- **Two-Phase Transfers**: Initiate and confirm mechanism for secure transfers
- **Fee Collection**: Configurable transfer fees collected by designated address
- **Transfer Expiry**: Automatic expiration of pending transfers after maximum block height
- **Comprehensive Validation**: Input validation and error handling
- **Transfer Cancellation**: Senders can cancel pending transfers with fee refund
- **Owner Controls**: Contract owner can update fees and fee collector

## Constants & Limits

- **Maximum Transfer Amount**: 1,000,000 STX
- **Minimum Transfer Amount**: 1 STX
- **Default Transfer Fee**: 10 STX
- **Transfer Expiry**: 500 blocks
- **Maximum Fee**: 1,000 STX

## Core Functions

### Public Functions

#### `initiate-transfer`
```clarity
(initiate-transfer (recipient principal) (amount uint))
```
Creates a new pending transfer. Collects the transfer fee immediately.

**Parameters:**
- `recipient`: Principal address receiving the transfer
- `amount`: Amount of STX to transfer (between 1 and 1,000,000)

**Returns:** Transfer ID on success

#### `confirm-transfer`
```clarity
(confirm-transfer (sender principal) (recipient principal) (transfer-id uint))
```
Confirms and executes a pending transfer. Must be called by the recipient.

**Parameters:**
- `sender`: Original sender's principal address
- `recipient`: Recipient's principal address (must match tx-sender)
- `transfer-id`: ID of the transfer to confirm

#### `cancel-transfer`
```clarity
(cancel-transfer (recipient principal) (transfer-id uint))
```
Cancels a pending transfer and refunds the fee. Must be called by the original sender.

**Parameters:**
- `recipient`: Recipient's principal address
- `transfer-id`: ID of the transfer to cancel

### Administrative Functions

#### `set-transfer-fee`
```clarity
(set-transfer-fee (new-fee uint))
```
Updates the transfer fee. Only callable by contract owner.

#### `set-fee-collector`
```clarity
(set-fee-collector (new-collector principal))
```
Updates the fee collection address. Only callable by contract owner.

### Read-Only Functions

#### `get-transfer-details`
```clarity
(get-transfer-details (sender principal) (recipient principal) (transfer-id uint))
```
Retrieves details of a specific transfer.

#### `get-contract-info`
```clarity
(get-contract-info)
```
Returns contract statistics and configuration.

## Transfer States

- **`pending`**: Transfer initiated but not yet confirmed
- **`completed`**: Transfer successfully confirmed and executed
- **`cancelled`**: Transfer cancelled by sender

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED | Caller not authorized for this operation |
| 101 | ERR-INVALID-TRANSFER | Invalid transfer parameters or state |
| 102 | ERR-TRANSFER-EXISTS | Transfer already exists |
| 103 | ERR-TRANSFER-NOT-FOUND | Transfer not found |
| 104 | ERR-INSUFFICIENT-FUNDS | Insufficient balance for transfer + fee |
| 105 | ERR-TRANSFER-EXPIRED | Transfer has exceeded expiry limit |
| 106 | ERR-INVALID-PARAMETER | Invalid input parameter |

## Usage Example

```clarity
;; 1. Alice initiates transfer to Bob
(contract-call? .proof-of-transfer initiate-transfer 'SP2BOB... u1000)
;; Returns: (ok u0) - transfer ID 0

;; 2. Bob confirms the transfer
(contract-call? .proof-of-transfer confirm-transfer 'SP1ALICE... 'SP2BOB... u0)
;; Returns: (ok true) - transfer completed

;; Alternative: Alice cancels before Bob confirms
(contract-call? .proof-of-transfer cancel-transfer 'SP2BOB... u0)
;; Returns: (ok true) - transfer cancelled, fee refunded
```

## Security Features

- Prevents self-transfers
- Validates transfer amounts within safe limits
- Prevents transfers to/from contract owner
- Automatic transfer expiration
- Fee collection before transfer execution
- Comprehensive input validation

## Deployment Notes

- Contract owner is set to the deploying address
- Default fee collector is the contract owner
- All transfers are tracked with incremental IDs
- Transfer history is permanently stored on-chain

## Gas Considerations

- `initiate-transfer`: ~2,000 gas
- `confirm-transfer`: ~3,000 gas
- `cancel-transfer`: ~2,500 gas
- Read operations: ~1,000 gas
