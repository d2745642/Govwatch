(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_FUND_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_FUND_ALREADY_EXISTS (err u103))
(define-constant ERR_AUDIT_NOT_FOUND (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_INVALID_STATUS (err u106))

(define-data-var next-fund-id uint u1)
(define-data-var next-audit-id uint u1)

(define-map public-funds
  { fund-id: uint }
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    allocated-amount: uint,
    spent-amount: uint,
    department: (string-ascii 50),
    created-by: principal,
    created-at: uint,
    status: (string-ascii 20)
  }
)

(define-map fund-transactions
  { fund-id: uint, tx-id: uint }
  {
    amount: uint,
    recipient: (string-ascii 100),
    purpose: (string-ascii 200),
    timestamp: uint,
    recorded-by: principal
  }
)

(define-map citizen-audits
  { audit-id: uint }
  {
    fund-id: uint,
    auditor: principal,
    findings: (string-ascii 1000),
    severity: (string-ascii 20),
    status: (string-ascii 20),
    created-at: uint,
    votes-for: uint,
    votes-against: uint
  }
)

(define-map audit-votes
  { audit-id: uint, voter: principal }
  { vote: bool, timestamp: uint }
)

(define-map authorized-officials
  { official: principal }
  { department: (string-ascii 50), authorized: bool }
)

(define-map fund-tx-counter
  { fund-id: uint }
  { count: uint }
)

(define-public (authorize-official (official principal) (department (string-ascii 50)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-officials
      { official: official }
      { department: department, authorized: true }
    ))
  )
)

(define-public (revoke-official (official principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (ok (map-set authorized-officials
      { official: official }
      { department: "", authorized: false }
    ))
  )
)

(define-public (create-fund (name (string-ascii 100)) (description (string-ascii 500)) (allocated-amount uint) (department (string-ascii 50)))
  (let
    (
      (fund-id (var-get next-fund-id))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (> allocated-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? public-funds { fund-id: fund-id })) ERR_FUND_ALREADY_EXISTS)
    (map-set public-funds
      { fund-id: fund-id }
      {
        name: name,
        description: description,
        allocated-amount: allocated-amount,
        spent-amount: u0,
        department: department,
        created-by: tx-sender,
        created-at: stacks-block-height,
        status: "active"
      }
    )
    (map-set fund-tx-counter { fund-id: fund-id } { count: u0 })
    (var-set next-fund-id (+ fund-id u1))
    (ok fund-id)
  )
)

(define-public (record-transaction (fund-id uint) (amount uint) (recipient (string-ascii 100)) (purpose (string-ascii 200)))
  (let
    (
      (fund-data (map-get? public-funds { fund-id: fund-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
      (tx-counter-data (default-to { count: u0 } (map-get? fund-tx-counter { fund-id: fund-id })))
      (tx-id (+ (get count tx-counter-data) u1))
    )
    (asserts! (is-some fund-data) ERR_FUND_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (let
      (
        (fund (unwrap-panic fund-data))
        (new-spent-amount (+ (get spent-amount fund) amount))
      )
      (asserts! (<= new-spent-amount (get allocated-amount fund)) ERR_INVALID_AMOUNT)
      (map-set public-funds
        { fund-id: fund-id }
        (merge fund { spent-amount: new-spent-amount })
      )
      (map-set fund-transactions
        { fund-id: fund-id, tx-id: tx-id }
        {
          amount: amount,
          recipient: recipient,
          purpose: purpose,
          timestamp: stacks-block-height,
          recorded-by: tx-sender
        }
      )
      (map-set fund-tx-counter { fund-id: fund-id } { count: tx-id })
      (ok tx-id)
    )
  )
)

(define-public (submit-audit (fund-id uint) (findings (string-ascii 1000)) (severity (string-ascii 20)))
  (let
    (
      (audit-id (var-get next-audit-id))
      (fund-data (map-get? public-funds { fund-id: fund-id }))
    )
    (asserts! (is-some fund-data) ERR_FUND_NOT_FOUND)
    (map-set citizen-audits
      { audit-id: audit-id }
      {
        fund-id: fund-id,
        auditor: tx-sender,
        findings: findings,
        severity: severity,
        status: "pending",
        created-at: stacks-block-height,
        votes-for: u0,
        votes-against: u0
      }
    )
    (var-set next-audit-id (+ audit-id u1))
    (ok audit-id)
  )
)

(define-public (vote-on-audit (audit-id uint) (vote bool))
  (let
    (
      (audit-data (map-get? citizen-audits { audit-id: audit-id }))
      (existing-vote (map-get? audit-votes { audit-id: audit-id, voter: tx-sender }))
    )
    (asserts! (is-some audit-data) ERR_AUDIT_NOT_FOUND)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (let
      (
        (audit (unwrap-panic audit-data))
        (new-votes-for (if vote (+ (get votes-for audit) u1) (get votes-for audit)))
        (new-votes-against (if vote (get votes-against audit) (+ (get votes-against audit) u1)))
      )
      (map-set citizen-audits
        { audit-id: audit-id }
        (merge audit {
          votes-for: new-votes-for,
          votes-against: new-votes-against
        })
      )
      (map-set audit-votes
        { audit-id: audit-id, voter: tx-sender }
        { vote: vote, timestamp: stacks-block-height }
      )
      (ok true)
    )
  )
)

(define-public (update-fund-status (fund-id uint) (new-status (string-ascii 20)))
  (let
    (
      (fund-data (map-get? public-funds { fund-id: fund-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some fund-data) ERR_FUND_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (map-set public-funds
      { fund-id: fund-id }
      (merge (unwrap-panic fund-data) { status: new-status })
    )
    (ok true)
  )
)

(define-read-only (get-fund (fund-id uint))
  (map-get? public-funds { fund-id: fund-id })
)

(define-read-only (get-transaction (fund-id uint) (tx-id uint))
  (map-get? fund-transactions { fund-id: fund-id, tx-id: tx-id })
)

(define-read-only (get-audit (audit-id uint))
  (map-get? citizen-audits { audit-id: audit-id })
)

(define-read-only (get-fund-utilization (fund-id uint))
  (match (map-get? public-funds { fund-id: fund-id })
    fund-data
    (let
      (
        (allocated (get allocated-amount fund-data))
        (spent (get spent-amount fund-data))
      )
      (ok {
        allocated: allocated,
        spent: spent,
        remaining: (- allocated spent),
        utilization-rate: (if (> allocated u0) (/ (* spent u100) allocated) u0)
      })
    )
    ERR_FUND_NOT_FOUND
  )
)

(define-read-only (is-authorized-official (official principal))
  (match (map-get? authorized-officials { official: official })
    official-data (get authorized official-data)
    false
  )
)

(define-read-only (get-audit-vote (audit-id uint) (voter principal))
  (map-get? audit-votes { audit-id: audit-id, voter: voter })
)

(define-read-only (get-fund-transaction-count (fund-id uint))
  (default-to { count: u0 } (map-get? fund-tx-counter { fund-id: fund-id }))
)

(define-read-only (get-next-fund-id)
  (var-get next-fund-id)
)

(define-read-only (get-next-audit-id)
  (var-get next-audit-id)
)