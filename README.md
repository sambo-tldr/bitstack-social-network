# BitStack Social Network

A comprehensive decentralized social networking platform built on the Stacks blockchain, leveraging Bitcoin's Layer 2 security and providing enterprise-grade privacy controls, intelligent rate limiting, and advanced user management features.

## Overview

BitStack Social Network delivers a fully decentralized social media experience with robust security, privacy-first design, and intelligent resource optimization. Built using Clarity smart contracts, it provides a censorship-resistant platform where users maintain complete control over their data and interactions.

## Key Features

### 🔐 Advanced Security & Privacy

- **Granular Privacy Controls**: Users can control visibility of friend lists, status updates, metadata, last-seen timestamps, and profile images
- **Encryption Support**: Optional end-to-end encryption with user-managed keys
- **Blocking System**: Comprehensive user blocking functionality for enhanced safety

### ⚡ Intelligent Rate Limiting

- **Adaptive Rate Management**: Dynamic rate limiting with automatic reset mechanisms
- **Action-Specific Limits**: Separate limits for friend requests, status updates, and general actions
- **Configurable Thresholds**: Customizable limits to prevent spam and abuse

### 📊 Batch Processing & Optimization

- **Dynamic Batch Sizing**: Intelligent batch size optimization based on usage patterns
- **Automatic Optimization**: Self-adjusting batch parameters for optimal performance
- **Resource Efficiency**: Minimizes transaction costs through smart batching

### 👥 Advanced Social Features

- **Bidirectional Friendships**: Comprehensive friendship management with status tracking
- **User Activity Analytics**: Detailed tracking of user engagement and activity patterns
- **Session Management**: Secure login tracking and session analytics

## Smart Contract Functions

### User Management

```clarity
;; Register new user
(register-user (name (string-ascii 64)))

;; Update user profile with optional encryption
(update-user-profile 
    (name (optional (string-ascii 64)))
    (metadata (optional (string-utf8 256)))
    (encryption-key (optional (buff 32)))
    (profile-image (optional (string-utf8 256))))

;; Record user login for analytics
(record-login)
```

### Privacy Controls

```clarity
;; Configure advanced privacy settings
(update-advanced-privacy-settings
    (friend-list-visible bool)
    (status-visible bool)
    (metadata-visible bool)
    (last-seen-visible bool)
    (profile-image-visible bool)
    (encryption-enabled bool))
```

### Batch Optimization

```clarity
;; Optimize batch processing for user
(optimize-batch-size)

;; Manually set batch size within allowed bounds
(set-batch-size (new-size uint))
```

### Read-Only Functions

```clarity
;; Get user profile with privacy filtering
(get-user-profile (user principal))

;; Get user activity data with privacy controls
(get-user-activity (user principal))
```

## Configuration Constants

### Rate Limiting

- **Daily Actions Limit**: 100 actions per user per day
- **Friend Requests Limit**: 20 requests per user per day  
- **Status Updates Limit**: 24 updates per user per day
- **Reset Period**: 24 hours (86,400 seconds)

### Batch Processing

- **Minimum Batch Size**: 10 items
- **Maximum Batch Size**: 100 items
- **Batch Expiry**: 1 hour (3,600 seconds)

### User Status Types

- **Active** (1): Normal operational status
- **Deactivated** (0): Temporarily disabled account
- **Suspended** (2): Account under review or penalty

## Security Features

### Access Control

- **Caller Verification**: All functions verify transaction sender authorization
- **User State Validation**: Comprehensive checks for user existence and status
- **Input Sanitization**: Robust validation of all user inputs

### Error Handling

- **Comprehensive Error Codes**: Detailed error reporting for all failure scenarios
- **Graceful Degradation**: Secure fallback behavior for edge cases
- **No Panic Conditions**: Proper error handling without contract failures

### Privacy Protection

- **Data Minimization**: Optional data fields with user-controlled visibility
- **Encryption Support**: Built-in support for user-managed encryption keys
- **Selective Disclosure**: Granular control over information sharing

## Installation & Deployment

### Prerequisites

- Clarinet CLI installed
- Stacks blockchain testnet/mainnet access
- STX tokens for deployment and transactions

### Deployment Steps

1. Clone the repository
2. Review and configure constants in the contract
3. Run security checks:

   ```bash
   clarinet check
   ```

4. Deploy to testnet:

   ```bash
   clarinet deploy --testnet
   ```

5. Verify contract functionality with test suite

### Testing

The contract includes comprehensive test coverage for:

- User registration and profile management
- Privacy settings and data visibility
- Rate limiting enforcement
- Batch processing optimization
- Friendship and blocking systems

## Integration Guidelines

### Frontend Integration

```javascript
// Example user registration
const registerUser = async (userName) => {
  const functionArgs = [stringAsciiCV(userName)];
  return await callContract('register-user', functionArgs);
};

// Example privacy update
const updatePrivacy = async (settings) => {
  const functionArgs = [
    boolCV(settings.friendListVisible),
    boolCV(settings.statusVisible),
    // ... other privacy settings
  ];
  return await callContract('update-advanced-privacy-settings', functionArgs);
};
```

### API Integration

The contract emits structured events for all major actions, enabling easy integration with monitoring and analytics systems:

```clarity
{
  event: "user-registered",
  user: principal,
  name: string,
  timestamp: uint
}
```

## Roadmap

### Phase 1 (Current)

- ✅ Core user management
- ✅ Privacy controls
- ✅ Rate limiting
- ✅ Batch optimization

### Phase 2 (Planned)

- 🔄 Advanced friendship features
- 🔄 Content sharing and messaging
- 🔄 Reputation system
- 🔄 Advanced analytics dashboard

### Phase 3 (Future)

- 📋 Cross-chain compatibility
- 📋 Advanced encryption protocols
- 📋 Decentralized governance
- 📋 Mobile application support

## Security Considerations

### Best Practices Implemented

- **Zero-Trust Architecture**: Every function call is validated
- **Principle of Least Privilege**: Users can only access their own data
- **Defense in Depth**: Multiple layers of security validation
- **Secure by Default**: Conservative privacy and security defaults

### Known Limitations

- Rate limiting resets are based on block height, not wall-clock time
- Batch optimization requires manual triggering by users
- Privacy settings changes are immediately effective (no grace period)

## Contributing

We welcome contributions to BitStack Social Network. Please ensure all code follows Clarity best practices and includes comprehensive tests.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Implement changes with tests
4. Run `clarinet check` to verify security
5. Submit pull request with detailed description

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For technical support, feature requests, or security concerns:

- Create an issue on GitHub
- Join our community Discord
- Review documentation at [docs.bitstack.social]

---

### Built with ❤️ on Stacks • Secured by Bitcoin
