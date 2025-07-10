# Decentralized Identity Verification Protocol

A comprehensive blockchain-based identity management system that enables users to create, manage, and control their digital identities with verifiable credentials, delegated permissions, and decentralized trust mechanisms. Built on the Stacks blockchain using Clarity smart contracts.

## Overview

This protocol supports self-sovereign identity principles with cryptographic security, reputation scoring, and granular access control for Web3 applications. Users maintain full control over their digital identity while enabling trusted interactions in decentralized ecosystems.

## Key Features

### Self-Sovereign Identity
- User-controlled identity creation and management
- Decentralized identity verification
- Emergency recovery mechanisms
- Identity deactivation capabilities

### Verifiable Credentials
- Self-issued credentials
- Third-party credential verification
- Credential expiration management
- Credential revocation system

### Permission Delegation
- Granular permission management
- Time-bound delegations
- Transferable delegation options
- Purpose-specific access control

### Trust & Reputation System
- Community-driven trust ratings
- Tiered verification levels
- Transparent reputation tracking
- Decentralized trust scoring

### Activity Auditing
- Comprehensive audit logging
- Transparent system activity
- Accountability tracking
- Historical record keeping

## Technical Specifications

### Constants
- **Maximum Text Field Length**: 256 characters
- **Maximum Delegated Permissions**: 10 permissions per delegation
- **Credential Expiration**: 2,880 blocks (~48 hours)
- **Maximum Delegation Duration**: 52,560 blocks (~1 year)
- **Default Delegation Duration**: 8,760 blocks (~2 months)

### Data Structures

#### User Identity Profile
```clarity
{
  is-active: bool,
  public-display-name: (string-ascii 64),
  registration-block-height: uint,
  last-modification-block-height: uint,
  emergency-recovery-principal: (optional principal),
  community-trust-rating: uint,
  identity-verification-tier: uint
}
```

#### Verifiable Credential
```clarity
{
  credential-claim-data: (string-ascii 256),
  is-verified-by-issuer: bool,
  credential-issuer-principal: (optional principal),
  issuance-block-height: (optional uint),
  expiration-block-height: (optional uint),
  issuer-verification-notes: (optional (string-ascii 256))
}
```

#### Permission Delegation
```clarity
{
  permitted-action-list: (list 10 (string-ascii 32)),
  delegation-expiration-block-height: uint,
  delegation-purpose-description: (string-ascii 256),
  is-transferable-delegation: bool
}
```

## Function Reference

### Identity Management

#### `create-user-identity`
Creates a new user identity profile.
```clarity
(create-user-identity (desired-display-name (string-ascii 64)))
```
- **Parameters**: Display name for the identity
- **Returns**: Success/error response
- **Requirements**: User must not already have an identity

#### `update-display-name`
Updates the public display name of an existing identity.
```clarity
(update-display-name (new-display-name (string-ascii 64)))
```
- **Parameters**: New display name
- **Returns**: Success/error response
- **Requirements**: User must have an active identity

#### `deactivate-user-identity`
Deactivates a user's identity profile.
```clarity
(deactivate-user-identity)
```
- **Returns**: Success/error response
- **Requirements**: User must have an active identity

### Credential Management

#### `issue-self-credential`
Issues a self-attested credential.
```clarity
(issue-self-credential (credential-type-identifier (string-ascii 32)) (credential-claim-data (string-ascii 256)))
```
- **Parameters**: Credential type and claim data
- **Returns**: Success/error response
- **Requirements**: User must have an active identity

#### `verify-credential-as-issuer`
Verifies a credential as a trusted issuer.
```clarity
(verify-credential-as-issuer (credential-holder-principal principal) (credential-type-identifier (string-ascii 32)) (verification-notes (string-ascii 256)))
```
- **Parameters**: Credential holder, type, and verification notes
- **Returns**: Success/error response
- **Requirements**: Both issuer and holder must have active identities

#### `revoke-credential`
Revokes an owned credential.
```clarity
(revoke-credential (credential-type-identifier (string-ascii 32)))
```
- **Parameters**: Credential type identifier
- **Returns**: Success/error response
- **Requirements**: User must own the credential

### Permission Delegation

#### `grant-permission-delegation`
Grants permission delegation to another user.
```clarity
(grant-permission-delegation (permission-delegate-principal principal) (permitted-action-list (list 10 (string-ascii 32))) (delegation-duration-blocks uint) (is-transferable-delegation bool) (delegation-purpose-description (string-ascii 256)))
```
- **Parameters**: Delegate, permissions, duration, transferability, and purpose
- **Returns**: Success/error response
- **Requirements**: Both grantor and delegate must have active identities

#### `revoke-permission-delegation`
Revokes a previously granted permission delegation.
```clarity
(revoke-permission-delegation (permission-delegate-principal principal))
```
- **Parameters**: Delegate principal
- **Returns**: Success/error response
- **Requirements**: Delegation must exist

### Trust & Reputation

#### `increment-community-trust-rating`
Increases another user's trust rating.
```clarity
(increment-community-trust-rating (target-user-principal principal))
```
- **Parameters**: Target user principal
- **Returns**: Success/error response
- **Requirements**: Both users must have active identities

#### `decrement-community-trust-rating`
Decreases another user's trust rating.
```clarity
(decrement-community-trust-rating (target-user-principal principal))
```
- **Parameters**: Target user principal
- **Returns**: Success/error response
- **Requirements**: Both users must have active identities

### Read-Only Functions

#### `get-user-identity-profile`
Retrieves a user's identity profile.
```clarity
(get-user-identity-profile (target-user-principal principal))
```

#### `get-verifiable-credential`
Retrieves a specific credential.
```clarity
(get-verifiable-credential (credential-holder-principal principal) (credential-type-identifier (string-ascii 32)))
```

#### `get-permission-delegation`
Retrieves delegation information.
```clarity
(get-permission-delegation (permission-grantor-principal principal) (permission-delegate-principal principal))
```

#### `verify-identity-exists`
Checks if an identity exists and is active.
```clarity
(verify-identity-exists (target-user-principal principal))
```

#### `get-community-trust-rating`
Retrieves a user's trust rating.
```clarity
(get-community-trust-rating (target-user-principal principal))
```

#### `get-identity-verification-tier`
Retrieves a user's verification tier.
```clarity
(get-identity-verification-tier (target-user-principal principal))
```

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-UNAUTHORIZED-ACCESS | Unauthorized access attempt |
| 101 | ERR-IDENTITY-ALREADY-EXISTS | Identity already exists for user |
| 102 | ERR-IDENTITY-NOT-FOUND | Identity not found |
| 103 | ERR-CREDENTIAL-NOT-FOUND | Credential not found |
| 104 | ERR-INVALID-VERIFIER-IDENTITY | Invalid verifier identity |
| 105 | ERR-CREDENTIAL-EXPIRED | Credential has expired |
| 106 | ERR-DELEGATE-NOT-FOUND | Delegate not found |
| 107 | ERR-TEXT-EXCEEDS-MAXIMUM-LENGTH | Text exceeds maximum length |
| 108 | ERR-BLOCK-INFO-UNAVAILABLE | Block information unavailable |
| 109 | ERR-DELEGATION-EXPIRED | Delegation has expired |
| 110 | ERR-INVALID-INPUT-PARAMETERS | Invalid input parameters |

## Usage Examples

### Creating an Identity
```clarity
(contract-call? .identity-protocol create-user-identity "Alice Smith")
```

### Issuing a Self-Credential
```clarity
(contract-call? .identity-protocol issue-self-credential "education" "Bachelor of Science in Computer Science")
```

### Granting Permission Delegation
```clarity
(contract-call? .identity-protocol grant-permission-delegation 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  (list "read-profile" "update-credentials") 
  u17520 
  false 
  "Temporary access for verification")
```

### Verifying a Credential
```clarity
(contract-call? .identity-protocol verify-credential-as-issuer 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
  "education" 
  "Verified educational credentials through official transcripts")
```

## Security Considerations

1. **Identity Ownership**: Only the identity owner can modify their profile
2. **Credential Integrity**: Credentials are cryptographically secured
3. **Delegation Limits**: Built-in limits prevent abuse of delegation system
4. **Expiration Management**: Automatic expiration prevents stale permissions
5. **Audit Trail**: All activities are logged for transparency

## Development Setup

1. Install Clarinet CLI
2. Clone the repository
3. Navigate to the project directory
4. Run tests: `clarinet test`
5. Deploy locally: `clarinet deploy`