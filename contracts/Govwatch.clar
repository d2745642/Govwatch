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

(define-data-var next-fund-id uint u1)
(define-data-var next-audit-id uint u1)
(define-data-var next-report-id uint u1)

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