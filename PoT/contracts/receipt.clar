;; Enhanced Proof of Transfer Smart Contract
;; Improved error handling and input validation

;; Error constants
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-INVALID-TRANSFER (err u101))
(define-constant ERR-TRANSFER-EXISTS (err u102))
(define-constant ERR-TRANSFER-NOT-FOUND (err u103))
(define-constant ERR-INSUFFICIENT-FUNDS (err u104))
(define-constant ERR-TRANSFER-EXPIRED (err u105))
(define-constant ERR-INVALID-PARAMETER (err u106))

;; Contract settings
(define-constant CONTRACT-OWNER tx-sender)
(define-constant MAX-TRANSFER-EXPIRY u500) ;; Block height limit for transfer validity
(define-constant DEFAULT-TRANSFER-FEE u10)
(define-constant MAX-TRANSFER-AMOUNT u1000000) ;; Preventing unreasonably large transfers
(define-constant MIN-TRANSFER-AMOUNT u1) ;; Minimum transfer amount

;; Transfer record structure
(define-map transfers
  { 
    sender: principal,
    recipient: principal,
    transfer-id: uint 
  }
  { 
    amount: uint,
    fee: uint,
    created-at: uint,
    status: (string-ascii 20)
  }
)

;; Tracking transfers and configurations
(define-data-var total-transfers uint u0)
(define-data-var transfer-fee uint DEFAULT-TRANSFER-FEE)
(define-data-var fee-collector principal tx-sender)

;; Comprehensive inline input validation
(define-private (validate-transfer-inputs
  (sender principal)
  (recipient principal)
  (amount uint)
)
  (begin
    ;; Validate principals are not null or system addresses
    (asserts! (and 
      (not (is-eq sender CONTRACT-OWNER))
      (not (is-eq sender tx-sender))
      (not (is-eq recipient CONTRACT-OWNER))
      (not (is-eq recipient tx-sender))
    ) ERR-INVALID-PARAMETER)
    
    ;; Prevent self-transfers
    (asserts! (not (is-eq sender recipient)) ERR-INVALID-TRANSFER)
    
    ;; Validate transfer amount
    (asserts! 
      (and 
        (>= amount MIN-TRANSFER-AMOUNT)
        (<= amount MAX-TRANSFER-AMOUNT)
      ) 
      ERR-INVALID-TRANSFER
    )
    
    (ok true)
  )
)

;; Initiate a new transfer
(define-public (initiate-transfer 
  (recipient principal) 
  (amount uint)
)
  (let 
    (
      (sender tx-sender)
      (current-fee (var-get transfer-fee))
      (transfer-id (var-get total-transfers))
      (fee-collector-address (var-get fee-collector))
    )
    ;; Validate all inputs inline
    (asserts! (and
      (not (is-eq recipient CONTRACT-OWNER))
      (not (is-eq recipient tx-sender))
      (>= amount MIN-TRANSFER-AMOUNT)
      (<= amount MAX-TRANSFER-AMOUNT)
    ) ERR-INVALID-PARAMETER)
    
    ;; Check sender's balance
    (asserts! 
      (>= 
        (stx-get-balance sender) 
        (+ amount current-fee)
      ) 
      ERR-INSUFFICIENT-FUNDS
    )
    
    ;; Collect transfer fee
    (try! 
      (stx-transfer? 
        current-fee 
        sender 
        fee-collector-address
      )
    )
    
    ;; Store transfer details
    (map-set transfers 
      {
        sender: sender, 
        recipient: recipient, 
        transfer-id: transfer-id
      }
      {
        amount: amount,
        fee: current-fee,
        created-at: block-height,
        status: "pending"
      }
    )
    
    ;; Increment transfer counter
    (var-set total-transfers (+ transfer-id u1))
    
    (ok transfer-id)
  )
)

;; Confirm a transfer
(define-public (confirm-transfer 
  (sender principal)
  (recipient principal)
  (transfer-id uint)
)
  (let (
    (transfer-details 
      (unwrap! 
        (map-get? transfers 
          {
            sender: sender, 
            recipient: recipient, 
            transfer-id: transfer-id
          }
        ) 
        ERR-TRANSFER-NOT-FOUND
      )
    )
    (current-block block-height)
  )
    ;; Validate transfer inputs
    (asserts! (and
      (not (is-eq sender CONTRACT-OWNER))
      (not (is-eq sender tx-sender))
      (not (is-eq recipient CONTRACT-OWNER))
      (not (is-eq recipient tx-sender))
      (< transfer-id (var-get total-transfers))
    ) ERR-INVALID-PARAMETER)
    
    ;; Validate confirmation
    (asserts! (is-eq tx-sender recipient) ERR-UNAUTHORIZED)
    
    ;; Check transfer status and expiry
    (asserts! 
      (and 
        (is-eq (get status transfer-details) "pending")
        (< (- current-block (get created-at transfer-details)) MAX-TRANSFER-EXPIRY)
      ) 
      ERR-TRANSFER-EXPIRED
    )
    
    ;; Transfer tokens
    (try! 
      (stx-transfer? 
        (get amount transfer-details)
        sender 
        recipient
      )
    )
    
    ;; Update transfer status
    (map-set transfers 
      {
        sender: sender, 
        recipient: recipient, 
        transfer-id: transfer-id
      }
      (merge transfer-details { status: "completed" })
    )
    
    (ok true)
  )
)

;; Cancel a transfer
(define-public (cancel-transfer 
  (recipient principal)
  (transfer-id uint)
)
  (let (
    (transfer-details 
      (unwrap! 
        (map-get? transfers 
          {
            sender: tx-sender, 
            recipient: recipient, 
            transfer-id: transfer-id
          }
        ) 
        ERR-TRANSFER-NOT-FOUND
      )
    )
  )
    ;; Validate recipient and transfer-id
    (asserts! (and
      (not (is-eq recipient CONTRACT-OWNER))
      (not (is-eq recipient tx-sender))
      (< transfer-id (var-get total-transfers))
    ) ERR-INVALID-PARAMETER)
    
    ;; Validate cancellation
    (asserts! 
      (is-eq (get status transfer-details) "pending") 
      ERR-INVALID-TRANSFER
    )
    
    ;; Refund transfer fee
    (try! 
      (stx-transfer? 
        (get fee transfer-details)
        (var-get fee-collector)
        tx-sender
      )
    )
    
    ;; Update transfer status
    (map-set transfers 
      {
        sender: tx-sender, 
        recipient: recipient, 
        transfer-id: transfer-id
      }
      (merge transfer-details { status: "cancelled" })
    )
    
    (ok true)
  )
)

;; Retrieve transfer details
(define-read-only (get-transfer-details 
  (sender principal)
  (recipient principal)
  (transfer-id uint)
)
  (map-get? transfers 
    {
      sender: sender, 
      recipient: recipient, 
      transfer-id: transfer-id
    }
  )
)

;; Update transfer fee (only by contract owner)
(define-public (set-transfer-fee (new-fee uint))
  (begin
    ;; Validate fee amount
    (asserts! 
      (and 
        (> new-fee u0) 
        (<= new-fee u1000)
      ) 
      ERR-INVALID-PARAMETER
    )
    
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set transfer-fee new-fee)
    (ok true)
  )
)

;; Update fee collector (only by contract owner)
(define-public (set-fee-collector (new-collector principal))
  (begin
    ;; Validate new collector address
    (asserts! (not (is-eq new-collector CONTRACT-OWNER)) ERR-INVALID-PARAMETER)
    
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (var-set fee-collector new-collector)
    (ok true)
  )
)

;; Contract information query
(define-read-only (get-contract-info)
  {
    total-transfers: (var-get total-transfers),
    current-fee: (var-get transfer-fee),
    fee-collector: (var-get fee-collector),
    contract-owner: CONTRACT-OWNER
  }
)

