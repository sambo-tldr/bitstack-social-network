;;
;; BitStack Social Network
;; A comprehensive social networking platform built on Stacks blockchain
;;
;; This contract provides a decentralized social networking infrastructure with advanced
;; privacy controls, rate limiting, batch processing, and friendship management.
;; Built for Bitcoin's Layer 2 with full Stacks compliance and security features.
;;
;; Features:
;; - Decentralized user profiles with encryption support
;; - Advanced friendship system with blocking capabilities
;; - Intelligent rate limiting and batch processing
;; - Granular privacy controls for user data
;; - Activity tracking and analytics
;; - Secure authentication and session management
;;

;; ERROR CODES & CONSTANTS

;; Error codes for comprehensive error handling
(define-constant ERR_NOT_FOUND (err u100))
(define-constant ERR_ALREADY_EXISTS (err u101))
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_INVALID_INPUT (err u103))
(define-constant ERR_BLOCKED (err u104))
(define-constant ERR_DEACTIVATED (err u105))
(define-constant ERR_RATE_LIMITED (err u106))
(define-constant ERR_BATCH_FULL (err u107))
(define-constant ERR_BATCH_EXPIRED (err u108))

;; User status constants
(define-constant STATUS_DEACTIVATED u0)
(define-constant STATUS_ACTIVE u1)
(define-constant STATUS_SUSPENDED u2)

;; Friendship status constants
(define-constant FRIENDSHIP_PENDING u0)
(define-constant FRIENDSHIP_ACTIVE u1)
(define-constant FRIENDSHIP_BLOCKED u2)

;; Rate limiting configuration
(define-constant MAX_ACTIONS_PER_DAY u100)
(define-constant MAX_FRIEND_REQUESTS_PER_DAY u20)
(define-constant MAX_STATUS_UPDATES_PER_DAY u24)
(define-constant RATE_LIMIT_RESET_PERIOD u86400) ;; 24 hours in seconds

;; Batch processing configuration
(define-constant MIN_BATCH_SIZE u10)
(define-constant MAX_BATCH_SIZE u100)
(define-constant BATCH_EXPIRY_PERIOD u3600) ;; 1 hour in seconds

;; DATA STRUCTURES

;; Primary user data storage with comprehensive profile information
(define-map Users
  principal
  {
    name: (string-ascii 64),
    status: uint,
    timestamp: uint,
    metadata: (optional (string-utf8 256)),
    deactivation-time: (optional uint),
    encryption-key: (optional (buff 32)),
    profile-image: (optional (string-utf8 256)),
  }
)

;; Advanced privacy settings for granular user control
(define-map UserPrivacy
  principal
  {
    friend-list-visible: bool,
    status-visible: bool,
    metadata-visible: bool,
    last-seen-visible: bool,
    profile-image-visible: bool,
    encryption-enabled: bool,
    last-updated: uint,
  }
)

;; Rate limiting tracking to prevent spam and abuse
(define-map RateLimits
  principal
  {
    daily-actions: uint,
    friend-requests: uint,
    status-updates: uint,
    last-reset: uint,
  }
)

;; Intelligent batch processing for message optimization
(define-map UserBatches
  principal
  {
    message-counter: uint,
    last-batch-timestamp: uint,
    batch-size: uint,
    current-batch-items: uint,
    total-batches: uint,
  }
)

;; Comprehensive user activity analytics
(define-map UserActivity
  principal
  {
    last-seen: uint,
    login-count: uint,
    total-actions: uint,
    last-action: uint,
  }
)

;; Bidirectional friendship management system
(define-map Friendships
  {
    user1: principal,
    user2: principal,
  }
  { status: uint }
)

;; User blocking system for enhanced security
(define-map BlockedUsers
  {
    blocker: principal,
    blocked: principal,
  }
  { timestamp: uint }
)

;; PRIVATE UTILITY FUNCTIONS

;; Intelligent rate limiting with automatic reset functionality
(define-private (check-rate-limit
    (user principal)
    (action-type uint)
  )
  (let (
      (rate-data (default-to {
        daily-actions: u0,
        friend-requests: u0,
        status-updates: u0,
        last-reset: stacks-block-height,
      }
        (map-get? RateLimits user)
      ))
      (current-time stacks-block-height)
      (should-reset (> (- current-time (get last-reset rate-data)) RATE_LIMIT_RESET_PERIOD))
    )
    (if should-reset
      ;; Reset counters if period expired
      (begin
        (map-set RateLimits user {
          daily-actions: u1,
          friend-requests: (if (is-eq action-type u1)
            u1
            u0
          ),
          status-updates: (if (is-eq action-type u2)
            u1
            u0
          ),
          last-reset: current-time,
        })
        true
      )
      ;; Check against configured limits
      (and
        (< (get daily-actions rate-data) MAX_ACTIONS_PER_DAY)
        (or
          (not (is-eq action-type u1))
          (< (get friend-requests rate-data) MAX_FRIEND_REQUESTS_PER_DAY)
        )
        (or
          (not (is-eq action-type u2))
          (< (get status-updates rate-data) MAX_STATUS_UPDATES_PER_DAY)
        )
      )
    )
  )
)

;; Update rate limiting counters after successful action
(define-private (update-rate-limit
    (user principal)
    (action-type uint)
  )
  (let ((rate-data (unwrap-panic (map-get? RateLimits user))))
    (map-set RateLimits user
      (merge rate-data {
        daily-actions: (+ (get daily-actions rate-data) u1),
        friend-requests: (+ (get friend-requests rate-data)
          (if (is-eq action-type u1)
            u1
            u0
          )),
        status-updates: (+ (get status-updates rate-data)
          (if (is-eq action-type u2)
            u1
            u0
          )),
      })
    )
  )
)

;; Comprehensive user activity tracking
(define-private (update-user-activity (user principal))
  (let (
      (current-time stacks-block-height)
      (activity (default-to {
        last-seen: current-time,
        login-count: u0,
        total-actions: u0,
        last-action: current-time,
      }
        (map-get? UserActivity user)
      ))
    )
    (map-set UserActivity user
      (merge activity {
        last-seen: current-time,
        total-actions: (+ (get total-actions activity) u1),
        last-action: current-time,
      })
    )
  )
)

;; Mathematical utility functions
(define-private (max-uint
    (a uint)
    (b uint)
  )
  (if (>= a b)
    a
    b
  )
)

(define-private (min-uint
    (a uint)
    (b uint)
  )
  (if (<= a b)
    a
    b
  )
)

;; Friendship validation with comprehensive status checking
(define-private (are-friends
    (user1 principal)
    (user2 principal)
  )
  (match (map-get? Friendships {
    user1: user1,
    user2: user2,
  })
    friendship (is-eq (get status friendship) FRIENDSHIP_ACTIVE)
    false
  )
)

;; Active user validation with deactivation checks
(define-private (check-active-user (user principal))
  (match (map-get? Users user)
    user-data (and
      (is-eq (get status user-data) STATUS_ACTIVE)
      (is-none (get deactivation-time user-data))
    )
    false
  )
)

;; User existence validation
(define-private (user-exists (user principal))
  (is-some (map-get? Users user))
)

;; Blocking relationship validation
(define-private (is-blocked
    (blocker principal)
    (blocked principal)
  )
  (is-some (map-get? BlockedUsers {
    blocker: blocker,
    blocked: blocked,
  }))
)

;; Privacy settings retrieval with secure defaults
(define-private (get-privacy-settings (user principal))
  (default-to {
    friend-list-visible: true,
    status-visible: true,
    metadata-visible: true,
    last-seen-visible: true,
    profile-image-visible: true,
    encryption-enabled: false,
    last-updated: stacks-block-height,
  }
    (map-get? UserPrivacy user)
  )
)

;; PUBLIC FUNCTIONS

;; FIXED: Intelligent batch size optimization with proper authorization and validation
(define-public (optimize-batch-size)
  (let (
      (caller tx-sender)
      (batch-data (unwrap! (map-get? UserBatches caller) ERR_NOT_FOUND))
      (current-time stacks-block-height)
      (time-since-last-batch (- current-time (get last-batch-timestamp batch-data)))
      (current-batch-size (get batch-size batch-data))
      (items-in-current-batch (get current-batch-items batch-data))
    )
    ;; Security checks
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (check-rate-limit caller u0) ERR_RATE_LIMITED)
    (if (> time-since-last-batch BATCH_EXPIRY_PERIOD)
      ;; Batch expired, reset and optimize size
      (begin
        (map-set UserBatches caller
          (merge batch-data {
            batch-size: (max-uint MIN_BATCH_SIZE (/ current-batch-size u2)),
            current-batch-items: u0,
            last-batch-timestamp: current-time,
          })
        )
        (update-rate-limit caller u0)
        (update-user-activity caller)
        (ok true)
      )
      ;; Dynamic adjustment based on usage patterns
      (begin
        (map-set UserBatches caller
          (merge batch-data { batch-size: (min-uint MAX_BATCH_SIZE
            (if (>= items-in-current-batch (/ current-batch-size u2))
              (* current-batch-size u2)
              current-batch-size
            )) }
          ))
        (update-rate-limit caller u0)
        (update-user-activity caller)
        (ok true)
      )
    )
  )
)

;; Advanced privacy settings management with granular controls
(define-public (update-advanced-privacy-settings
    (friend-list-visible bool)
    (status-visible bool)
    (metadata-visible bool)
    (last-seen-visible bool)
    (profile-image-visible bool)
    (encryption-enabled bool)
  )
  (let ((caller tx-sender))
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (check-rate-limit caller u2) ERR_RATE_LIMITED)
    (map-set UserPrivacy caller {
      friend-list-visible: friend-list-visible,
      status-visible: status-visible,
      metadata-visible: metadata-visible,
      last-seen-visible: last-seen-visible,
      profile-image-visible: profile-image-visible,
      encryption-enabled: encryption-enabled,
      last-updated: stacks-block-height,
    })
    (update-rate-limit caller u2)
    (update-user-activity caller)
    (print {
      event: "privacy-updated",
      user: caller,
      timestamp: stacks-block-height,
    })
    (ok true)
  )
)

;; Comprehensive user profile management with encryption support
(define-public (update-user-profile
    (name (optional (string-ascii 64)))
    (metadata (optional (string-utf8 256)))
    (encryption-key (optional (buff 32)))
    (profile-image (optional (string-utf8 256)))
  )
  (let (
      (caller tx-sender)
      (user (unwrap! (map-get? Users caller) ERR_NOT_FOUND))
    )
    (asserts! (check-active-user caller) ERR_DEACTIVATED)
    (asserts! (check-rate-limit caller u2) ERR_RATE_LIMITED)
    (map-set Users caller
      (merge user {
        name: (default-to (get name user) name),
        metadata: (if (is-some metadata)
          metadata
          (get metadata user)
        ),
        encryption-key: (if (is-some encryption-key)
          encryption-key
          (get encryption-key user)
        ),
        profile-image: (if (is-some profile-image)
          profile-image
          (get profile-image user)
        ),
      })
    )
    (update-rate-limit caller u2)
    (update-user-activity caller)
    (print {
      event: "profile-updated",
      user: caller,
      timestamp: stacks-block-height,
    })
    (ok true)
  )
)