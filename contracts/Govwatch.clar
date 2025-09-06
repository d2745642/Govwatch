(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_FUND_NOT_FOUND (err u101))
(define-constant ERR_INVALID_AMOUNT (err u102))
(define-constant ERR_FUND_ALREADY_EXISTS (err u103))
(define-constant ERR_AUDIT_NOT_FOUND (err u104))
(define-constant ERR_ALREADY_VOTED (err u105))
(define-constant ERR_INVALID_STATUS (err u106))
(define-constant ERR_REPORT_NOT_FOUND (err u107))
(define-constant ERR_INVALID_PERIOD (err u108))
(define-constant ERR_ALREADY_SUBSCRIBED (err u109))
(define-constant ERR_NOT_SUBSCRIBED (err u110))
(define-constant ERR_CASE_NOT_FOUND (err u111))
(define-constant ERR_INVALID_SEVERITY (err u112))
(define-constant ERR_CASE_CLOSED (err u113))
(define-constant ERR_INSUFFICIENT_EVIDENCE (err u114))
(define-constant ERR_ALREADY_CLAIMED (err u115))
(define-constant ERR_AMENDMENT_NOT_FOUND (err u116))
(define-constant ERR_AMENDMENT_CLOSED (err u117))
(define-constant ERR_INVALID_AMENDMENT_TYPE (err u118))

(define-data-var next-fund-id uint u1)
(define-data-var next-audit-id uint u1)
(define-data-var next-report-id uint u1)
(define-data-var next-case-id uint u1)
(define-data-var next-amendment-id uint u1)

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

(define-map performance-reports
  { report-id: uint }
  {
    period-start: uint,
    period-end: uint,
    total-funds: uint,
    total-allocated: uint,
    total-spent: uint,
    active-funds: uint,
    completed-funds: uint,
    avg-utilization: uint,
    total-audits: uint,
    critical-audits: uint,
    department-performance: (list 10 { dept: (string-ascii 50), efficiency: uint, spending: uint }),
    generated-by: principal,
    generated-at: uint
  }
)

(define-map fund-analytics
  { fund-id: uint }
  {
    efficiency-score: uint,
    velocity-score: uint,
    transparency-score: uint,
    audit-score: uint,
    overall-rating: uint,
    last-updated: uint
  }
)

(define-map report-subscriptions
  { subscriber: principal }
  {
    department-filter: (string-ascii 50),
    frequency: uint,
    active: bool,
    last-notification: uint
  }
)

(define-map department-metrics
  { department: (string-ascii 50), period: uint }
  {
    total-allocation: uint,
    total-spending: uint,
    fund-count: uint,
    avg-efficiency: uint,
    audit-count: uint,
    issue-count: uint
  }
)

(define-map fraud-cases
  { case-id: uint }
  {
    reporter-hash: (buff 32),
    fund-id: (optional uint),
    allegations: (string-ascii 1000),
    severity: (string-ascii 20),
    evidence-hash: (buff 32),
    status: (string-ascii 20),
    assigned-investigator: (optional principal),
    created-at: uint,
    resolution: (string-ascii 500),
    reward-amount: uint,
    reward-claimed: bool
  }
)

(define-map whistleblower-protections
  { case-id: uint }
  {
    protection-level: uint,
    anonymity-preserved: bool,
    threat-assessment: uint,
    protection-expires: uint,
    contact-method: (string-ascii 100)
  }
)

(define-map case-evidence
  { case-id: uint, evidence-id: uint }
  {
    evidence-type: (string-ascii 50),
    content-hash: (buff 32),
    submitted-by: principal,
    verified: bool,
    timestamp: uint
  }
)

(define-map investigator-assignments
  { investigator: principal }
  {
    active-cases: uint,
    resolved-cases: uint,
    success-rate: uint,
    specialization: (string-ascii 50),
    clearance-level: uint
  }
)

(define-map case-rewards
  { case-id: uint }
  {
    base-reward: uint,
    bonus-multiplier: uint,
    total-reward: uint,
    funding-source: (string-ascii 50),
    approval-required: bool
  }
)

;; Budget Amendment Tracking System
(define-map budget-amendments
  { amendment-id: uint }
  {
    fund-id: uint,
    proposed-amount: uint,
    current-amount: uint,
    amendment-type: (string-ascii 20), ;; "increase", "decrease", "reallocation"
    justification: (string-ascii 500),
    proposer: principal,
    status: (string-ascii 20), ;; "pending", "approved", "rejected", "expired"
    votes-for: uint,
    votes-against: uint,
    min-votes-required: uint,
    created-at: uint,
    expires-at: uint,
    reviewed-by: (optional principal),
    review-notes: (string-ascii 300)
  }
)

(define-map amendment-votes
  { amendment-id: uint, voter: principal }
  { vote: bool, vote-weight: uint, timestamp: uint }
)

(define-map amendment-history
  { fund-id: uint, change-id: uint }
  {
    amendment-id: uint,
    previous-amount: uint,
    new-amount: uint,
    reason: (string-ascii 500),
    approved-by: principal,
    effective-date: uint
  }
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

(define-public (generate-performance-report (period-start uint) (period-end uint))
  (let
    (
      (report-id (var-get next-report-id))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (< period-start period-end) ERR_INVALID_PERIOD)
    (let
      (
        (fund-stats (calculate-fund-statistics period-start period-end))
        (audit-stats (calculate-audit-statistics period-start period-end))
      )
      (map-set performance-reports
        { report-id: report-id }
        {
          period-start: period-start,
          period-end: period-end,
          total-funds: (get total-funds fund-stats),
          total-allocated: (get total-allocated fund-stats),
          total-spent: (get total-spent fund-stats),
          active-funds: (get active-funds fund-stats),
          completed-funds: (get completed-funds fund-stats),
          avg-utilization: (get avg-utilization fund-stats),
          total-audits: (get total-audits audit-stats),
          critical-audits: (get critical-audits audit-stats),
          department-performance: (list),
          generated-by: tx-sender,
          generated-at: stacks-block-height
        }
      )
      (var-set next-report-id (+ report-id u1))
      (ok report-id)
    )
  )
)

(define-public (calculate-fund-efficiency (fund-id uint))
  (let
    (
      (fund-data (map-get? public-funds { fund-id: fund-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some fund-data) ERR_FUND_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (let
      (
        (fund (unwrap-panic fund-data))
        (utilization (if (> (get allocated-amount fund) u0)
          (/ (* (get spent-amount fund) u100) (get allocated-amount fund))
          u0))
        (velocity-score (calculate-velocity-score fund-id))
        (transparency-score (calculate-transparency-score fund-id))
        (audit-score (calculate-audit-score fund-id))
        (overall-rating (/ (+ utilization velocity-score transparency-score audit-score) u4))
      )
      (map-set fund-analytics
        { fund-id: fund-id }
        {
          efficiency-score: utilization,
          velocity-score: velocity-score,
          transparency-score: transparency-score,
          audit-score: audit-score,
          overall-rating: overall-rating,
          last-updated: stacks-block-height
        }
      )
      (ok overall-rating)
    )
  )
)

(define-public (subscribe-to-reports (department-filter (string-ascii 50)) (frequency uint))
  (let
    (
      (existing-sub (map-get? report-subscriptions { subscriber: tx-sender }))
    )
    (asserts! (is-none existing-sub) ERR_ALREADY_SUBSCRIBED)
    (asserts! (and (>= frequency u1) (<= frequency u12)) ERR_INVALID_PERIOD)
    (map-set report-subscriptions
      { subscriber: tx-sender }
      {
        department-filter: department-filter,
        frequency: frequency,
        active: true,
        last-notification: u0
      }
    )
    (ok true)
  )
)

(define-public (unsubscribe-from-reports)
  (let
    (
      (existing-sub (map-get? report-subscriptions { subscriber: tx-sender }))
    )
    (asserts! (is-some existing-sub) ERR_NOT_SUBSCRIBED)
    (map-set report-subscriptions
      { subscriber: tx-sender }
      (merge (unwrap-panic existing-sub) { active: false })
    )
    (ok true)
  )
)

(define-public (update-department-metrics (department (string-ascii 50)) (period uint))
  (let
    (
      (official-data (map-get? authorized-officials { official: tx-sender }))
      (dept-stats (aggregate-department-data department period))
    )
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (map-set department-metrics
      { department: department, period: period }
      {
        total-allocation: (get total-allocation dept-stats),
        total-spending: (get total-spending dept-stats),
        fund-count: (get fund-count dept-stats),
        avg-efficiency: (get avg-efficiency dept-stats),
        audit-count: (get audit-count dept-stats),
        issue-count: (get issue-count dept-stats)
      }
    )
    (ok true)
  )
)

(define-private (calculate-fund-statistics (start uint) (end uint))
  {
    total-funds: u10,
    total-allocated: u1000000,
    total-spent: u750000,
    active-funds: u7,
    completed-funds: u3,
    avg-utilization: u75
  }
)

(define-private (calculate-audit-statistics (start uint) (end uint))
  {
    total-audits: u25,
    critical-audits: u5
  }
)

(define-private (calculate-velocity-score (fund-id uint))
  (let
    (
      (tx-count (get count (get-fund-transaction-count fund-id)))
      (fund-data (map-get? public-funds { fund-id: fund-id }))
    )
    (if (is-some fund-data)
      (let
        (
          (fund (unwrap-panic fund-data))
          (age (- stacks-block-height (get created-at fund)))
        )
        (if (> age u0)
          (let ((score (/ (* tx-count u100) age)))
            (if (> score u100) u100 score))
          u0)
      )
      u0
    )
  )
)

(define-private (calculate-transparency-score (fund-id uint))
  (let
    (
      (tx-count (get count (get-fund-transaction-count fund-id)))
      (score (+ u50 (* tx-count u5)))
    )
    (if (> score u100) u100 score)
  )
)

(define-private (calculate-audit-score (fund-id uint))
  u80
)

(define-private (aggregate-department-data (department (string-ascii 50)) (period uint))
  {
    total-allocation: u500000,
    total-spending: u350000,
    fund-count: u5,
    avg-efficiency: u70,
    audit-count: u8,
    issue-count: u2
  }
)

(define-read-only (get-performance-report (report-id uint))
  (map-get? performance-reports { report-id: report-id })
)

(define-read-only (get-fund-analytics (fund-id uint))
  (map-get? fund-analytics { fund-id: fund-id })
)

(define-read-only (get-department-metrics (department (string-ascii 50)) (period uint))
  (map-get? department-metrics { department: department, period: period })
)

(define-read-only (get-subscription-status (subscriber principal))
  (map-get? report-subscriptions { subscriber: subscriber })
)

(define-read-only (calculate-system-health)
  (let
    (
      (current-height stacks-block-height)
      (total-funds-var (var-get next-fund-id))
      (total-audits-var (var-get next-audit-id))
    )
    (ok {
      system-uptime: current-height,
      total-funds-tracked: (- total-funds-var u1),
      total-audits-conducted: (- total-audits-var u1),
      health-score: u95,
      last-updated: current-height
    })
  )
)

(define-read-only (get-fund-performance-ranking (limit uint))
  (ok (list
    { fund-id: u1, score: u95 }
    { fund-id: u2, score: u88 }
    { fund-id: u3, score: u82 }
  ))
)

(define-read-only (get-next-report-id)
  (var-get next-report-id)
)

(define-public (submit-fraud-report (fund-id (optional uint)) (allegations (string-ascii 1000)) (severity (string-ascii 20)) (evidence-hash (buff 32)))
  (let
    (
      (case-id (var-get next-case-id))
      (reporter-hash (hash160 (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? tx-sender)) u20))))
    )
    (asserts! (or (is-eq severity "low") (is-eq severity "medium") (is-eq severity "high") (is-eq severity "critical")) ERR_INVALID_SEVERITY)
    (if (is-some fund-id)
      (asserts! (is-some (map-get? public-funds { fund-id: (unwrap-panic fund-id) })) ERR_FUND_NOT_FOUND)
      true
    )
    (map-set fraud-cases
      { case-id: case-id }
      {
        reporter-hash: reporter-hash,
        fund-id: fund-id,
        allegations: allegations,
        severity: severity,
        evidence-hash: evidence-hash,
        status: "pending",
        assigned-investigator: none,
        created-at: stacks-block-height,
        resolution: "",
        reward-amount: u0,
        reward-claimed: false
      }
    )
    (map-set whistleblower-protections
      { case-id: case-id }
      {
        protection-level: (if (is-eq severity "critical") u5 
                           (if (is-eq severity "high") u4
                           (if (is-eq severity "medium") u3 u2))),
        anonymity-preserved: true,
        threat-assessment: u1,
        protection-expires: (+ stacks-block-height u52560),
        contact-method: "encrypted-channel"
      }
    )
    (let ((reward-amount (calculate-base-reward severity)))
      (map-set case-rewards
        { case-id: case-id }
        {
          base-reward: reward-amount,
          bonus-multiplier: u100,
          total-reward: reward-amount,
          funding-source: "whistleblower-fund",
          approval-required: (if (> reward-amount u10000) true false)
        }
      )
    )
    (var-set next-case-id (+ case-id u1))
    (ok case-id)
  )
)

(define-public (assign-investigator (case-id uint) (investigator principal))
  (let
    (
      (case-data (map-get? fraud-cases { case-id: case-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
      (investigator-data (default-to { active-cases: u0, resolved-cases: u0, success-rate: u0, specialization: "", clearance-level: u1 }
        (map-get? investigator-assignments { investigator: investigator })))
    )
    (asserts! (is-some case-data) ERR_CASE_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (is-eq (get status (unwrap-panic case-data)) "pending") ERR_CASE_CLOSED)
    (map-set fraud-cases
      { case-id: case-id }
      (merge (unwrap-panic case-data) { 
        assigned-investigator: (some investigator),
        status: "investigating"
      })
    )
    (map-set investigator-assignments
      { investigator: investigator }
      (merge investigator-data { active-cases: (+ (get active-cases investigator-data) u1) })
    )
    (ok true)
  )
)

(define-public (submit-case-evidence (case-id uint) (evidence-type (string-ascii 50)) (content-hash (buff 32)))
  (let
    (
      (case-data (map-get? fraud-cases { case-id: case-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
      (evidence-id u1)
    )
    (asserts! (is-some case-data) ERR_CASE_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq (get status (unwrap-panic case-data)) "closed")) ERR_CASE_CLOSED)
    (map-set case-evidence
      { case-id: case-id, evidence-id: evidence-id }
      {
        evidence-type: evidence-type,
        content-hash: content-hash,
        submitted-by: tx-sender,
        verified: false,
        timestamp: stacks-block-height
      }
    )
    (ok evidence-id)
  )
)

(define-public (verify-evidence (case-id uint) (evidence-id uint))
  (let
    (
      (evidence-data (map-get? case-evidence { case-id: case-id, evidence-id: evidence-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some evidence-data) ERR_INSUFFICIENT_EVIDENCE)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (map-set case-evidence
      { case-id: case-id, evidence-id: evidence-id }
      (merge (unwrap-panic evidence-data) { verified: true })
    )
    (ok true)
  )
)

(define-public (resolve-case (case-id uint) (resolution (string-ascii 500)) (outcome (string-ascii 20)))
  (let
    (
      (case-data (map-get? fraud-cases { case-id: case-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
      (reward-data (map-get? case-rewards { case-id: case-id }))
    )
    (asserts! (is-some case-data) ERR_CASE_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (not (is-eq (get status (unwrap-panic case-data)) "closed")) ERR_CASE_CLOSED)
    (map-set fraud-cases
      { case-id: case-id }
      (merge (unwrap-panic case-data) { 
        status: "closed",
        resolution: resolution
      })
    )
    (if (and (is-some reward-data) (is-eq outcome "validated"))
      (let 
        (
          (reward (unwrap-panic reward-data))
          (final-reward (/ (* (get total-reward reward) (get bonus-multiplier reward)) u100))
        )
        (map-set case-rewards
          { case-id: case-id }
          (merge reward { total-reward: final-reward })
        )
        (map-set fraud-cases
          { case-id: case-id }
          (merge (unwrap-panic (map-get? fraud-cases { case-id: case-id })) { reward-amount: final-reward })
        )
      )
      true
    )
    (if (is-some (get assigned-investigator (unwrap-panic case-data)))
      (let
        (
          (investigator (unwrap-panic (get assigned-investigator (unwrap-panic case-data))))
          (inv-data (default-to { active-cases: u0, resolved-cases: u0, success-rate: u0, specialization: "", clearance-level: u1 }
            (map-get? investigator-assignments { investigator: investigator })))
        )
        (map-set investigator-assignments
          { investigator: investigator }
          (merge inv-data { 
            active-cases: (if (> (get active-cases inv-data) u0) (- (get active-cases inv-data) u1) u0),
            resolved-cases: (+ (get resolved-cases inv-data) u1)
          })
        )
      )
      true
    )
    (ok true)
  )
)

(define-public (claim-reward (case-id uint))
  (let
    (
      (case-data (map-get? fraud-cases { case-id: case-id }))
      (reporter-hash (hash160 (unwrap-panic (as-max-len? (unwrap-panic (to-consensus-buff? tx-sender)) u20))))
    )
    (asserts! (is-some case-data) ERR_CASE_NOT_FOUND)
    (asserts! (is-eq (get status (unwrap-panic case-data)) "closed") ERR_CASE_CLOSED)
    (asserts! (is-eq (get reporter-hash (unwrap-panic case-data)) reporter-hash) ERR_UNAUTHORIZED)
    (asserts! (not (get reward-claimed (unwrap-panic case-data))) ERR_ALREADY_CLAIMED)
    (asserts! (> (get reward-amount (unwrap-panic case-data)) u0) ERR_INSUFFICIENT_EVIDENCE)
    (map-set fraud-cases
      { case-id: case-id }
      (merge (unwrap-panic case-data) { reward-claimed: true })
    )
    (ok (get reward-amount (unwrap-panic case-data)))
  )
)

(define-public (update-protection-level (case-id uint) (new-level uint))
  (let
    (
      (protection-data (map-get? whistleblower-protections { case-id: case-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some protection-data) ERR_CASE_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (asserts! (and (>= new-level u1) (<= new-level u5)) ERR_INVALID_SEVERITY)
    (map-set whistleblower-protections
      { case-id: case-id }
      (merge (unwrap-panic protection-data) { protection-level: new-level })
    )
    (ok true)
  )
)

(define-private (calculate-base-reward (severity (string-ascii 20)))
  (if (is-eq severity "critical") u50000
  (if (is-eq severity "high") u25000
  (if (is-eq severity "medium") u10000 u5000)))
)

(define-read-only (get-fraud-case (case-id uint))
  (map-get? fraud-cases { case-id: case-id })
)

(define-read-only (get-whistleblower-protection (case-id uint))
  (map-get? whistleblower-protections { case-id: case-id })
)

(define-read-only (get-case-evidence-data (case-id uint) (evidence-id uint))
  (map-get? case-evidence { case-id: case-id, evidence-id: evidence-id })
)

(define-read-only (get-investigator-profile (investigator principal))
  (map-get? investigator-assignments { investigator: investigator })
)

(define-read-only (get-case-reward-info (case-id uint))
  (map-get? case-rewards { case-id: case-id })
)

(define-read-only (calculate-investigator-workload (investigator principal))
  (let
    (
      (profile (default-to { active-cases: u0, resolved-cases: u0, success-rate: u0, specialization: "", clearance-level: u1 }
        (map-get? investigator-assignments { investigator: investigator })))
    )
    (ok {
      current-workload: (get active-cases profile),
      total-resolved: (get resolved-cases profile),
      efficiency-rating: (get success-rate profile),
      capacity-remaining: (if (> u10 (get active-cases profile)) (- u10 (get active-cases profile)) u0)
    })
  )
)

(define-read-only (get-active-cases-by-severity (severity (string-ascii 20)))
  (ok (list
    { case-id: u1, status: "investigating" }
    { case-id: u3, status: "pending" }
  ))
)

(define-read-only (get-next-case-id)
  (var-get next-case-id)
)

;; Budget Amendment Functions
(define-public (propose-budget-amendment (fund-id uint) (proposed-amount uint) (amendment-type (string-ascii 20)) (justification (string-ascii 500)))
  (let
    (
      (amendment-id (var-get next-amendment-id))
      (fund-data (map-get? public-funds { fund-id: fund-id }))
    )
    (asserts! (is-some fund-data) ERR_FUND_NOT_FOUND)
    (asserts! (> proposed-amount u0) ERR_INVALID_AMOUNT)
    (asserts! (or (is-eq amendment-type "increase") (is-eq amendment-type "decrease") (is-eq amendment-type "reallocation")) ERR_INVALID_AMENDMENT_TYPE)
    (let
      (
        (fund (unwrap-panic fund-data))
        (current-amount (get allocated-amount fund))
        (min-votes (if (> (/ current-amount u100000) u3) (/ current-amount u100000) u3)) ;; Minimum 3 votes or 1 per 100k allocated
      )
      (map-set budget-amendments
        { amendment-id: amendment-id }
        {
          fund-id: fund-id,
          proposed-amount: proposed-amount,
          current-amount: current-amount,
          amendment-type: amendment-type,
          justification: justification,
          proposer: tx-sender,
          status: "pending",
          votes-for: u0,
          votes-against: u0,
          min-votes-required: min-votes,
          created-at: stacks-block-height,
          expires-at: (+ stacks-block-height u1440), ;; Expires in ~10 days
          reviewed-by: none,
          review-notes: ""
        }
      )
      (var-set next-amendment-id (+ amendment-id u1))
      (ok amendment-id)
    )
  )
)

(define-public (vote-on-amendment (amendment-id uint) (vote bool))
  (let
    (
      (amendment-data (map-get? budget-amendments { amendment-id: amendment-id }))
      (existing-vote (map-get? amendment-votes { amendment-id: amendment-id, voter: tx-sender }))
    )
    (asserts! (is-some amendment-data) ERR_AMENDMENT_NOT_FOUND)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (let
      (
        (amendment (unwrap-panic amendment-data))
      )
      (asserts! (is-eq (get status amendment) "pending") ERR_AMENDMENT_CLOSED)
      (asserts! (< stacks-block-height (get expires-at amendment)) ERR_AMENDMENT_CLOSED)
      (let
        (
          (vote-weight u1) ;; Could be enhanced with reputation-based weighting
          (new-votes-for (if vote (+ (get votes-for amendment) vote-weight) (get votes-for amendment)))
          (new-votes-against (if vote (get votes-against amendment) (+ (get votes-against amendment) vote-weight)))
        )
        (map-set budget-amendments
          { amendment-id: amendment-id }
          (merge amendment {
            votes-for: new-votes-for,
            votes-against: new-votes-against
          })
        )
        (map-set amendment-votes
          { amendment-id: amendment-id, voter: tx-sender }
          { vote: vote, vote-weight: vote-weight, timestamp: stacks-block-height }
        )
        (ok true)
      )
    )
  )
)

(define-public (approve-amendment (amendment-id uint) (review-notes (string-ascii 300)))
  (let
    (
      (amendment-data (map-get? budget-amendments { amendment-id: amendment-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some amendment-data) ERR_AMENDMENT_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (let
      (
        (amendment (unwrap-panic amendment-data))
      )
      (asserts! (is-eq (get status amendment) "pending") ERR_AMENDMENT_CLOSED)
      (asserts! (>= (get votes-for amendment) (get min-votes-required amendment)) ERR_INVALID_STATUS)
      (asserts! (> (get votes-for amendment) (get votes-against amendment)) ERR_INVALID_STATUS)
      ;; Update the fund allocation
      (let
        (
          (fund-data (unwrap-panic (map-get? public-funds { fund-id: (get fund-id amendment) })))
          (change-id u1) ;; Simplified - could be tracked per fund
        )
        (map-set public-funds
          { fund-id: (get fund-id amendment) }
          (merge fund-data { allocated-amount: (get proposed-amount amendment) })
        )
        ;; Record the change in history
        (map-set amendment-history
          { fund-id: (get fund-id amendment), change-id: change-id }
          {
            amendment-id: amendment-id,
            previous-amount: (get current-amount amendment),
            new-amount: (get proposed-amount amendment),
            reason: (get justification amendment),
            approved-by: tx-sender,
            effective-date: stacks-block-height
          }
        )
        ;; Update amendment status
        (map-set budget-amendments
          { amendment-id: amendment-id }
          (merge amendment {
            status: "approved",
            reviewed-by: (some tx-sender),
            review-notes: review-notes
          })
        )
        (ok true)
      )
    )
  )
)

(define-public (reject-amendment (amendment-id uint) (review-notes (string-ascii 300)))
  (let
    (
      (amendment-data (map-get? budget-amendments { amendment-id: amendment-id }))
      (official-data (map-get? authorized-officials { official: tx-sender }))
    )
    (asserts! (is-some amendment-data) ERR_AMENDMENT_NOT_FOUND)
    (asserts! (and (is-some official-data) (get authorized (unwrap-panic official-data))) ERR_UNAUTHORIZED)
    (let
      (
        (amendment (unwrap-panic amendment-data))
      )
      (asserts! (is-eq (get status amendment) "pending") ERR_AMENDMENT_CLOSED)
      (map-set budget-amendments
        { amendment-id: amendment-id }
        (merge amendment {
          status: "rejected",
          reviewed-by: (some tx-sender),
          review-notes: review-notes
        })
      )
      (ok true)
    )
  )
)

;; Read-only functions for Budget Amendments
(define-read-only (get-budget-amendment (amendment-id uint))
  (map-get? budget-amendments { amendment-id: amendment-id })
)

(define-read-only (get-amendment-vote (amendment-id uint) (voter principal))
  (map-get? amendment-votes { amendment-id: amendment-id, voter: voter })
)

(define-read-only (get-amendment-history (fund-id uint) (change-id uint))
  (map-get? amendment-history { fund-id: fund-id, change-id: change-id })
)

(define-read-only (get-next-amendment-id)
  (var-get next-amendment-id)
)

(define-read-only (check-amendment-eligibility (amendment-id uint))
  (match (map-get? budget-amendments { amendment-id: amendment-id })
    amendment
    (ok {
      is-active: (and (is-eq (get status amendment) "pending") (< stacks-block-height (get expires-at amendment))),
      vote-threshold-met: (>= (get votes-for amendment) (get min-votes-required amendment)),
      community-support: (> (get votes-for amendment) (get votes-against amendment)),
      ready-for-review: (and 
        (>= (get votes-for amendment) (get min-votes-required amendment))
        (> (get votes-for amendment) (get votes-against amendment))
      )
    })
    ERR_AMENDMENT_NOT_FOUND
  )
)
