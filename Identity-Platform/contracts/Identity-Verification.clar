;; Decentralized Identity Verification Protocol Smart Contract
;; Description: A comprehensive blockchain-based identity management system enabling users to create,
;; manage, and control their digital identities with verifiable credentials, delegated permissions,
;; and decentralized trust mechanisms. Supports self-sovereign identity principles with cryptographic
;; security, reputation scoring, and granular access control for Web3 applications.

;; SYSTEM CONFIGURATION & CONSTANTS

(define-constant protocol-administrator-address tx-sender)
(define-constant maximum-text-field-length u256)
(define-constant maximum-delegated-permissions u10)
(define-constant credential-expiration-blocks u2880) ;; 48 hours in blocks
(define-constant delegation-maximum-duration-blocks u52560) ;; 1 year in blocks
(define-constant default-delegation-duration-blocks u8760) ;; 2 months in blocks

;; ERROR CONSTANTS

(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-IDENTITY-ALREADY-EXISTS (err u101))
(define-constant ERR-IDENTITY-NOT-FOUND (err u102))
(define-constant ERR-CREDENTIAL-NOT-FOUND (err u103))
(define-constant ERR-INVALID-VERIFIER-IDENTITY (err u104))
(define-constant ERR-CREDENTIAL-EXPIRED (err u105))
(define-constant ERR-DELEGATE-NOT-FOUND (err u106))
(define-constant ERR-TEXT-EXCEEDS-MAXIMUM-LENGTH (err u107))
(define-constant ERR-BLOCK-INFO-UNAVAILABLE (err u108))
(define-constant ERR-DELEGATION-EXPIRED (err u109))
(define-constant ERR-INVALID-INPUT-PARAMETERS (err u110))

;; DATA STRUCTURES

;; User identity profile information
(define-map user-identity-profiles
  principal  
  {
    is-active: bool,
    public-display-name: (string-ascii 64),
    registration-block-height: uint,
    last-modification-block-height: uint,
    emergency-recovery-principal: (optional principal),
    community-trust-rating: uint,
    identity-verification-tier: uint
  }
)

;; Verifiable credential storage
(define-map verifiable-credentials
  {credential-holder-principal: principal, credential-type-identifier: (string-ascii 32)}
  {
    credential-claim-data: (string-ascii 256),
    is-verified-by-issuer: bool,
    credential-issuer-principal: (optional principal),
    issuance-block-height: (optional uint),
    expiration-block-height: (optional uint),
    issuer-verification-notes: (optional (string-ascii 256))
  }
)

;; Permission delegation records
(define-map permission-delegation-records
  {permission-grantor-principal: principal, permission-delegate-principal: principal}
  {
    permitted-action-list: (list 10 (string-ascii 32)),
    delegation-expiration-block-height: uint,
    delegation-purpose-description: (string-ascii 256),
    is-transferable-delegation: bool
  }
)

;; System activity audit log
(define-map system-activity-audit-log
  {activity-actor-principal: principal, activity-block-height: uint}
  {
    performed-action-type: (string-ascii 32),
    action-contextual-data: (optional (string-ascii 64)),
    action-initiator-principal: principal
  }
)

;; READ-ONLY QUERY FUNCTIONS

(define-read-only (get-user-identity-profile (target-user-principal principal))
  (match (map-get? user-identity-profiles target-user-principal)
    existing-profile-data existing-profile-data
    {
      is-active: false,
      public-display-name: "",
      registration-block-height: u0,
      last-modification-block-height: u0,
      emergency-recovery-principal: none,
      community-trust-rating: u0,
      identity-verification-tier: u0
    }
  )
)

(define-read-only (get-verifiable-credential (credential-holder-principal principal) (credential-type-identifier (string-ascii 32)))
  (map-get? verifiable-credentials {credential-holder-principal: credential-holder-principal, credential-type-identifier: credential-type-identifier})
)

(define-read-only (get-permission-delegation (permission-grantor-principal principal) (permission-delegate-principal principal))
  (map-get? permission-delegation-records {permission-grantor-principal: permission-grantor-principal, permission-delegate-principal: permission-delegate-principal})
)

(define-read-only (verify-identity-exists (target-user-principal principal))
  (match (map-get? user-identity-profiles target-user-principal)
    existing-profile-data (get is-active existing-profile-data)
    false
  )
)

(define-read-only (get-community-trust-rating (target-user-principal principal))
  (match (map-get? user-identity-profiles target-user-principal)
    existing-profile-data (get community-trust-rating existing-profile-data)
    u0
  )
)

(define-read-only (get-identity-verification-tier (target-user-principal principal))
  (match (map-get? user-identity-profiles target-user-principal)
    existing-profile-data (get identity-verification-tier existing-profile-data)
    u0
  )
)

;; VALIDATION HELPER FUNCTIONS

(define-private (validate-text-length (input-text-string (string-ascii 256)))
  (and 
    (>= (len input-text-string) u1)
    (<= (len input-text-string) maximum-text-field-length)
  )
)

(define-private (validate-bounded-text (input-text-string (string-ascii 256)) (maximum-allowed-length uint))
  (and 
    (>= (len input-text-string) u1)
    (<= (len input-text-string) maximum-allowed-length)
  )
)

(define-private (validate-permission-action-list (permission-action-list (list 10 (string-ascii 32))))
  (and
    (>= (len permission-action-list) u1)
    (<= (len permission-action-list) maximum-delegated-permissions)
    (is-eq (len permission-action-list) (len (filter validate-text-length permission-action-list)))
  )
)

(define-private (get-current-block-timestamp)
  (ok (unwrap! (get-block-info? time (- block-height u1)) ERR-BLOCK-INFO-UNAVAILABLE))
)

;; IDENTITY MANAGEMENT FUNCTIONS

(define-public (create-user-identity (desired-display-name (string-ascii 64)))
  (let
    (
      (requesting-user-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (not (verify-identity-exists requesting-user-principal)) ERR-IDENTITY-ALREADY-EXISTS)
    (asserts! (validate-bounded-text desired-display-name u64) ERR-INVALID-INPUT-PARAMETERS)
    (try! (record-system-activity "identity-registration" none))
    (ok (map-set user-identity-profiles
      requesting-user-principal
      {
        is-active: true,
        public-display-name: desired-display-name,
        registration-block-height: current-block-timestamp,
        last-modification-block-height: current-block-timestamp,
        emergency-recovery-principal: none,
        community-trust-rating: u1,
        identity-verification-tier: u0
      }
    ))
  )
)

(define-public (update-display-name (new-display-name (string-ascii 64)))
  (let
    (
      (requesting-user-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (verify-identity-exists requesting-user-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (validate-bounded-text new-display-name u64) ERR-INVALID-INPUT-PARAMETERS)
    (try! (record-system-activity "display-name-updated" none))
    (ok (map-set user-identity-profiles
      requesting-user-principal
      (merge (unwrap! (map-get? user-identity-profiles requesting-user-principal) ERR-IDENTITY-NOT-FOUND)
        {
          public-display-name: new-display-name,
          last-modification-block-height: current-block-timestamp
        }
      )
    ))
  )
)

(define-public (deactivate-user-identity)
  (let
    (
      (requesting-user-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (verify-identity-exists requesting-user-principal) ERR-IDENTITY-NOT-FOUND)
    (try! (record-system-activity "identity-deactivated" none))
    (ok (map-set user-identity-profiles
      requesting-user-principal
      (merge (unwrap! (map-get? user-identity-profiles requesting-user-principal) ERR-IDENTITY-NOT-FOUND)
        {
          is-active: false,
          last-modification-block-height: current-block-timestamp
        }
      )
    ))
  )
)

;; CREDENTIAL MANAGEMENT FUNCTIONS

(define-public (issue-self-credential (credential-type-identifier (string-ascii 32)) (credential-claim-data (string-ascii 256)))
  (let
    (
      (credential-holder-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (validate-bounded-text credential-type-identifier u32) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-bounded-text credential-claim-data u256) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (verify-identity-exists credential-holder-principal) ERR-IDENTITY-NOT-FOUND)
    
    (try! (record-system-activity "self-credential-issued" (some credential-type-identifier)))
    (ok (map-set verifiable-credentials
      {credential-holder-principal: credential-holder-principal, credential-type-identifier: credential-type-identifier}
      {
        credential-claim-data: credential-claim-data,
        is-verified-by-issuer: false,
        credential-issuer-principal: none,
        issuance-block-height: none,
        expiration-block-height: none,
        issuer-verification-notes: none
      }
    ))
  )
)

(define-public (verify-credential-as-issuer (credential-holder-principal principal) (credential-type-identifier (string-ascii 32)) (verification-notes (string-ascii 256)))
  (let
    (
      (credential-issuer-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
      (credential-expiration-timestamp (+ current-block-timestamp credential-expiration-blocks))
    )
    (asserts! (validate-bounded-text credential-type-identifier u32) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-bounded-text verification-notes u256) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (verify-identity-exists credential-holder-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (verify-identity-exists credential-issuer-principal) ERR-INVALID-VERIFIER-IDENTITY)
    
    (try! (record-system-activity "credential-verified" (some credential-type-identifier)))
    (ok (map-set verifiable-credentials
      {credential-holder-principal: credential-holder-principal, credential-type-identifier: credential-type-identifier}
      (merge (unwrap! (map-get? verifiable-credentials {credential-holder-principal: credential-holder-principal, credential-type-identifier: credential-type-identifier}) ERR-CREDENTIAL-NOT-FOUND)
        {
          is-verified-by-issuer: true,
          credential-issuer-principal: (some credential-issuer-principal),
          issuance-block-height: (some current-block-timestamp),
          expiration-block-height: (some credential-expiration-timestamp),
          issuer-verification-notes: (some verification-notes)
        }
      )
    ))
  )
)

(define-public (revoke-credential (credential-type-identifier (string-ascii 32)))
  (let
    (
      (credential-holder-principal tx-sender)
      (credential-lookup-key {credential-holder-principal: credential-holder-principal, credential-type-identifier: credential-type-identifier})
    )
    (asserts! (verify-identity-exists credential-holder-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-some (map-get? verifiable-credentials credential-lookup-key)) ERR-CREDENTIAL-NOT-FOUND)
    
    (try! (record-system-activity "credential-revoked" (some credential-type-identifier)))
    (ok (map-delete verifiable-credentials credential-lookup-key))
  )
)

;; PERMISSION DELEGATION FUNCTIONS

(define-public (grant-permission-delegation 
  (permission-delegate-principal principal) 
  (permitted-action-list (list 10 (string-ascii 32))) 
  (delegation-duration-blocks uint)
  (is-transferable-delegation bool)
  (delegation-purpose-description (string-ascii 256)))
  (let
    (
      (permission-grantor-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
      (validated-duration-blocks (if (<= delegation-duration-blocks delegation-maximum-duration-blocks)
                                   delegation-duration-blocks
                                   default-delegation-duration-blocks))
      (delegation-expiration-timestamp (+ current-block-timestamp validated-duration-blocks))
    )
    (asserts! (verify-identity-exists permission-grantor-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (verify-identity-exists permission-delegate-principal) ERR-DELEGATE-NOT-FOUND)
    (asserts! (validate-permission-action-list permitted-action-list) ERR-INVALID-INPUT-PARAMETERS)
    (asserts! (validate-bounded-text delegation-purpose-description u256) ERR-INVALID-INPUT-PARAMETERS)
    
    (try! (record-system-activity "permission-delegation-granted" none))
    (ok (map-set permission-delegation-records
      {permission-grantor-principal: permission-grantor-principal, permission-delegate-principal: permission-delegate-principal}
      {
        permitted-action-list: permitted-action-list,
        delegation-expiration-block-height: delegation-expiration-timestamp,
        delegation-purpose-description: delegation-purpose-description,
        is-transferable-delegation: is-transferable-delegation
      }
    ))
  )
)

(define-public (revoke-permission-delegation (permission-delegate-principal principal))
  (let
    (
      (permission-grantor-principal tx-sender)
      (delegation-lookup-key {permission-grantor-principal: permission-grantor-principal, permission-delegate-principal: permission-delegate-principal})
    )
    (asserts! (verify-identity-exists permission-grantor-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (is-some (map-get? permission-delegation-records delegation-lookup-key)) ERR-DELEGATE-NOT-FOUND)
    
    (try! (record-system-activity "permission-delegation-revoked" none))
    (ok (map-delete permission-delegation-records delegation-lookup-key))
  )
)

(define-public (configure-emergency-recovery-principal (emergency-recovery-principal principal))
  (let
    (
      (identity-owner-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (verify-identity-exists identity-owner-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (verify-identity-exists emergency-recovery-principal) ERR-IDENTITY-NOT-FOUND)
    (try! (record-system-activity "emergency-recovery-configured" none))
    (ok (map-set user-identity-profiles
      identity-owner-principal
      (merge (unwrap! (map-get? user-identity-profiles identity-owner-principal) ERR-IDENTITY-NOT-FOUND)
        {
          emergency-recovery-principal: (some emergency-recovery-principal),
          last-modification-block-height: current-block-timestamp
        }
      )
    ))
  )
)

;; TRUST & REPUTATION FUNCTIONS

(define-public (increment-community-trust-rating (target-user-principal principal))
  (let
    (
      (rating-modifier-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (verify-identity-exists target-user-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (verify-identity-exists rating-modifier-principal) ERR-IDENTITY-NOT-FOUND)
    (try! (record-system-activity "trust-rating-increased" none))
    (try! (modify-trust-rating target-user-principal 1))
    (ok true)
  )
)

(define-public (decrement-community-trust-rating (target-user-principal principal))
  (let
    (
      (rating-modifier-principal tx-sender)
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (asserts! (verify-identity-exists target-user-principal) ERR-IDENTITY-NOT-FOUND)
    (asserts! (verify-identity-exists rating-modifier-principal) ERR-IDENTITY-NOT-FOUND)
    (try! (record-system-activity "trust-rating-decreased" none))
    (try! (modify-trust-rating target-user-principal -1))
    (ok true)
  )
)

;; INTERNAL UTILITY FUNCTIONS

(define-private (record-system-activity (performed-action-type (string-ascii 32)) (action-contextual-data (optional (string-ascii 64))))
  (let
    (
      (current-block-timestamp (try! (get-current-block-timestamp)))
    )
    (map-set system-activity-audit-log
      {activity-actor-principal: tx-sender, activity-block-height: current-block-timestamp}
      {
        performed-action-type: performed-action-type,
        action-contextual-data: action-contextual-data,
        action-initiator-principal: tx-sender
      }
    )
    (ok true)
  )
)

(define-private (verify-delegation-is-valid (permission-grantor-principal principal) (permission-delegate-principal principal) (required-action-permission (string-ascii 32)))
  (match (map-get? permission-delegation-records {permission-grantor-principal: permission-grantor-principal, permission-delegate-principal: permission-delegate-principal})
    existing-delegation-data (and
      (>= (unwrap! (get-block-info? time (- block-height u1)) false)
          (get delegation-expiration-block-height existing-delegation-data))
      (is-some (index-of (get permitted-action-list existing-delegation-data) required-action-permission))
    )
    false
  )
)

(define-private (modify-trust-rating (target-user-principal principal) (rating-adjustment int))
  (match (map-get? user-identity-profiles target-user-principal)
    existing-profile-data 
    (let
      (
        (current-trust-rating (get community-trust-rating existing-profile-data))
        (adjusted-trust-rating (if (> rating-adjustment 0) 
                                (+ current-trust-rating u1) 
                                (if (> current-trust-rating u0) 
                                  (- current-trust-rating u1) 
                                  u0)))
      )
      (ok (map-set user-identity-profiles
        target-user-principal
        (merge existing-profile-data { community-trust-rating: adjusted-trust-rating })
      ))
    )
    ERR-IDENTITY-NOT-FOUND
  )
)

;; PROTOCOL INITIALIZATION

(begin
  (map-set user-identity-profiles
    protocol-administrator-address
    {
      is-active: true,
      public-display-name: "Protocol Administrator",
      registration-block-height: block-height,
      last-modification-block-height: block-height,
      emergency-recovery-principal: none,
      community-trust-rating: u1000,
      identity-verification-tier: u5
    }
  )
  (ok true)
)