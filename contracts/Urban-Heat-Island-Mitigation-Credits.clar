(define-fungible-token uhi-credit)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-not-verified (err u104))
(define-constant err-invalid-project (err u105))
(define-constant err-unauthorized (err u106))

(define-data-var next-project-id uint u1)
(define-data-var total-credits-minted uint u0)
(define-data-var verification-fee uint u1000000)

(define-map projects
  uint
  {
    owner: principal,
    project-type: (string-ascii 32),
    location: (string-ascii 128),
    area-sqm: uint,
    expected-credits: uint,
    verified: bool,
    verifier: (optional principal),
    credits-minted: uint,
    created-at: uint
  }
)

(define-map project-verifiers principal bool)

(define-map credit-offers
  {project-id: uint, seller: principal}
  {
    amount: uint,
    price-per-credit: uint,
    active: bool
  }
)

(define-map verified-measurements
  uint
  {
    temperature-reduction: uint,
    verification-date: uint,
    verifier: principal,
    drone-data-hash: (buff 32)
  }
)

(define-map allowances {owner: principal, spender: principal} uint)

(define-map locked-credits
  principal
  {
    amount: uint,
    unlock-height: uint,
    bonus-rate: uint
  }
)

(define-public (add-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-set project-verifiers verifier true))
  )
)

(define-public (remove-verifier (verifier principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (map-delete project-verifiers verifier))
  )
)

(define-public (register-project 
  (project-type (string-ascii 32))
  (location (string-ascii 128))
  (area-sqm uint)
  (expected-credits uint)
)
  (let ((project-id (var-get next-project-id)))
    (map-set projects project-id
      {
        owner: tx-sender,
        project-type: project-type,
        location: location,
        area-sqm: area-sqm,
        expected-credits: expected-credits,
        verified: false,
        verifier: none,
        credits-minted: u0,
        created-at: burn-block-height
      }
    )
    (var-set next-project-id (+ project-id u1))
    (ok project-id)
  )
)
(define-public (update-project
  (project-id uint)
  (new-project-type (string-ascii 32))
  (new-location (string-ascii 128))
  (new-area-sqm uint)
  (new-expected-credits uint)
)
  (let ((project (unwrap! (map-get? projects project-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    (asserts! (not (get verified project)) err-already-verified)
    (map-set projects project-id
      (merge project {
        project-type: new-project-type,
        location: new-location,
        area-sqm: new-area-sqm,
        expected-credits: new-expected-credits
      })
    )
    (ok true)
  )
)

(define-public (verify-project
  (project-id uint)
  (temperature-reduction uint)
  (drone-data-hash (buff 32))
)
  (let ((project (unwrap! (map-get? projects project-id) err-not-found)))
    (asserts! (default-to false (map-get? project-verifiers tx-sender)) err-unauthorized)
    (asserts! (not (get verified project)) err-already-verified)
    
    (map-set projects project-id
      (merge project {
        verified: true,
        verifier: (some tx-sender)
      })
    )
    
    (map-set verified-measurements project-id
      {
        temperature-reduction: temperature-reduction,
        verification-date: burn-block-height,
        verifier: tx-sender,
        drone-data-hash: drone-data-hash
      }
    )
    
    (ok true)
  )
)

(define-public (mint-credits (project-id uint))
  (let (
    (project (unwrap! (map-get? projects project-id) err-not-found))
    (credits-to-mint (get expected-credits project))
  )
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    (asserts! (get verified project) err-not-verified)
    (asserts! (is-eq (get credits-minted project) u0) err-already-verified)
    
    (try! (ft-mint? uhi-credit credits-to-mint tx-sender))
    
    (map-set projects project-id
      (merge project {credits-minted: credits-to-mint})
    )
    
    (var-set total-credits-minted 
      (+ (var-get total-credits-minted) credits-to-mint)
    )
    
    (ok credits-to-mint)
  )
)

(define-public (create-sell-offer
  (project-id uint)
  (amount uint)
  (price-per-credit uint)
)
  (let ((project (unwrap! (map-get? projects project-id) err-not-found)))
    (asserts! (is-eq tx-sender (get owner project)) err-unauthorized)
    (asserts! (>= (ft-get-balance uhi-credit tx-sender) amount) err-insufficient-balance)
    
    (map-set credit-offers
      {project-id: project-id, seller: tx-sender}
      {
        amount: amount,
        price-per-credit: price-per-credit,
        active: true
      }
    )
    
    (ok true)
  )
)

(define-public (buy-credits
  (project-id uint)
  (seller principal)
  (amount uint)
)
  (let (
    (offer (unwrap! (map-get? credit-offers {project-id: project-id, seller: seller}) err-not-found))
    (total-cost (* (get price-per-credit offer) amount))
  )
    (asserts! (get active offer) err-not-found)
    (asserts! (>= (get amount offer) amount) err-insufficient-balance)
    
    (try! (stx-transfer? total-cost tx-sender seller))
    (try! (ft-transfer? uhi-credit amount seller tx-sender))
    
    (if (is-eq (get amount offer) amount)
      (map-delete credit-offers {project-id: project-id, seller: seller})
      (map-set credit-offers
        {project-id: project-id, seller: seller}
        (merge offer {amount: (- (get amount offer) amount)})
      )
    )
    
    (ok amount)
  )
)

(define-public (retire-credits (amount uint))
  (begin
    (asserts! (>= (ft-get-balance uhi-credit tx-sender) amount) err-insufficient-balance)
    (try! (ft-burn? uhi-credit amount tx-sender))
    (ok amount)
  )
)

(define-public (approve (spender principal) (amount uint))
  (ok (map-set allowances {owner: tx-sender, spender: spender} amount))
)

(define-public (transfer-from (owner principal) (recipient principal) (amount uint))
  (let (
    (current-allowance (default-to u0 (map-get? allowances {owner: owner, spender: tx-sender})))
  )
    (asserts! (>= current-allowance amount) err-insufficient-balance)
    (try! (ft-transfer? uhi-credit amount owner recipient))
    (map-set allowances {owner: owner, spender: tx-sender} (- current-allowance amount))
    (ok amount)
  )
)

(define-public (increase-allowance (spender principal) (added-amount uint))
  (let (
    (current-allowance (default-to u0 (map-get? allowances {owner: tx-sender, spender: spender})))
  )
    (ok (map-set allowances {owner: tx-sender, spender: spender} (+ current-allowance added-amount)))
  )
)

(define-public (decrease-allowance (spender principal) (subtracted-amount uint))
  (let (
    (current-allowance (default-to u0 (map-get? allowances {owner: tx-sender, spender: spender})))
  )
    (asserts! (>= current-allowance subtracted-amount) err-insufficient-balance)
    (ok (map-set allowances {owner: tx-sender, spender: spender} (- current-allowance subtracted-amount)))
  )
)

(define-public (lock-credits (amount uint) (lock-period uint) (bonus-rate uint))
  (let (
    (current-balance (ft-get-balance uhi-credit tx-sender))
    (unlock-height (+ burn-block-height lock-period))
  )
    (asserts! (>= current-balance amount) err-insufficient-balance)
    (try! (ft-transfer? uhi-credit amount tx-sender (as-contract tx-sender)))
    (ok (map-set locked-credits tx-sender {
      amount: amount,
      unlock-height: unlock-height,
      bonus-rate: bonus-rate
    }))
  )
)

(define-public (unlock-credits)
  (let (
    (locked-data (unwrap! (map-get? locked-credits tx-sender) err-not-found))
    (current-height burn-block-height)
    (locked-amount (get amount locked-data))
    (unlock-height (get unlock-height locked-data))
    (bonus-rate (get bonus-rate locked-data))
    (bonus-amount (/ (* locked-amount bonus-rate) u100))
    (total-amount (+ locked-amount bonus-amount))
  )
    (asserts! (>= current-height unlock-height) err-unauthorized)
    (try! (as-contract (ft-transfer? uhi-credit total-amount tx-sender tx-sender)))
    (map-delete locked-credits tx-sender)
    (ok total-amount)
  )
)

(define-public (set-verification-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set verification-fee new-fee))
  )
)

(define-read-only (get-project (project-id uint))
  (map-get? projects project-id)
)

(define-read-only (get-verification (project-id uint))
  (map-get? verified-measurements project-id)
)

(define-read-only (get-credit-offer (project-id uint) (seller principal))
  (map-get? credit-offers {project-id: project-id, seller: seller})
)

(define-read-only (get-total-credits-minted)
  (var-get total-credits-minted)
)

(define-read-only (get-verification-fee)
  (var-get verification-fee)
)

(define-read-only (is-verifier (verifier principal))
  (default-to false (map-get? project-verifiers verifier))
)

(define-read-only (get-balance (account principal))
  (ft-get-balance uhi-credit account)
)

(define-read-only (get-allowance (owner principal) (spender principal))
  (default-to u0 (map-get? allowances {owner: owner, spender: spender}))
)

(define-read-only (get-locked-credits (account principal))
  (map-get? locked-credits account)
)

(define-read-only (get-token-uri)
  (ok (some "https://uhi-credits.com/metadata.json"))
)

(define-read-only (get-name)
  (ok "Urban Heat Island Mitigation Credits")
)

(define-read-only (get-symbol)
  (ok "UHI")
)

(define-read-only (get-decimals)
  (ok u6)
)

(define-read-only (get-total-supply)
  (ft-get-supply uhi-credit)
)
