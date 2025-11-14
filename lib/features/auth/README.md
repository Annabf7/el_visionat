# Authentication Feature

This module manages all authentication-related functionality in the El Visionat app, providing a complete system for registration, login, profile management, and route protection.

## Overview

The authentication system supports:

- **Manual Registration Flow**: License verification → Email submission → Manual approval → Token validation → Password creation
- **Login System**: Email/password authentication with Firebase Auth
- **Route Protection**: Automatic redirection for unauthorized access
- **Profile Management**: User profile display and logout functionality
- **Token-based Activation**: Secure email-based account activation

## Architecture

### Services

- **`AuthService`**: Core authentication business logic
  - Firebase Auth integration (with emulator support)
  - Cloud Functions communication (registration flow)
  - Email/password authentication
  - Session management and cleanup

### Providers

- **`AuthProvider`**: State management for authentication flow
  - Registration step machine (`RegistrationStep` enum)
  - User authentication state tracking
  - Error handling and loading states
  - Integration with Firebase Auth state changes

### Widgets

- **`RequireAuth`**: Route protection wrapper
  - Automatically redirects unauthenticated users to login
  - Centralized authentication guard for protected routes
- **`LoginView`**: Login form component
  - Email/password input with validation
  - Token activation dialog for approved users
  - Automatic profile display for authenticated users
- **`RegisterView`**: Multi-step registration container
  - Animated transitions between registration steps
  - Error recovery and state management

### Pages

- **`LoginPage`**: Main authentication page
  - Responsive design (mobile tabs, desktop columns)
  - Login and registration interfaces
  - Automatic redirection for authenticated users
- **`CreatePasswordPage`**: Final registration step
  - Password creation after approval
  - Route arguments validation
  - Account completion and automatic login

## Registration Flow

### Complete Registration Process

```
1. License Verification
   └── User enters license ID → `verifyLicense()` → Cloud Function `lookupLicense`

2. Email Submission
   └── User enters email → `submitRegistrationRequest()` → Cloud Function `requestRegistration`

3. Manual Approval
   └── Admin reviews and approves registration request

4. Token Validation
   └── User receives email → enters token → `validateActivationToken` Cloud Function

5. Password Creation
   └── Navigate to `/create-password` → `completeRegistrationProcess()`

6. Account Creation
   └── Cloud Function `completeRegistration` → Automatic login → Navigate to `/home`
```

### Registration States (RegistrationStep)

```dart
enum RegistrationStep {
  initial,                    // Starting state
  licenseLookup,             // Verifying license
  licenseVerified,           // License verified, ready for email
  requestingRegistration,    // Submitting registration request
  requestSent,              // Request sent, awaiting approval
  approvedNeedPassword,     // Approved, needs token validation
  completingRegistration,   // Creating account
  registrationComplete,     // Registration completed successfully
  error,                   // Error in process
}
```

## Login Flow

### Standard Login

```
1. User enters credentials → `signIn()`
2. Firebase Auth validates → `signInWithEmail()`
3. Success → Navigate to `/home`
4. Error → Display error message
```

### Smart Login Detection

```
1. Login fails with specific error codes
2. Check if user has approved registration → `checkApprovedStatus()`
3. If approved → Prompt for activation token
4. Token valid → Navigate to `/create-password`
5. Complete registration flow
```

## Route Protection

### Protected Routes

All routes using `RequireAuth` wrapper:

- `/home` - Main application
- `/all-matches` - Match listings
- `/profile` - User profile
- `/visionat` - Match analysis

### Navigation Logic

- **`AuthWrapper`**: Initial route decision (login vs home)
- **Automatic redirection**: Unauthenticated users → `/login`
- **Stack management**: Clean navigation history on auth state changes

## Firebase Integration

### Firebase Auth

- **Real authentication**: Complete Firebase Auth integration
- **Emulator support**: Automatic emulator configuration in debug mode
- **Error handling**: Specific error codes for registration flow detection

### Cloud Functions (Backend)

```typescript
// functions/src/auth/
lookupLicense.ts; // Verify license against official registry
requestRegistration.ts; // Submit registration for manual approval
completeRegistration.ts; // Create Firebase user after approval
checkRegistrationStatus.ts; // Check if email has approved registration
validateActivationToken.ts; // Validate email activation tokens
resendActivationToken.ts; // Resend activation tokens
```

### Firestore Collections

```
/emails/{email}                    // Email uniqueness reservation
/registration_requests/{id}        // Pending approval requests
/approved_registrations/{email}    // Approved registrations awaiting completion
/activation_tokens/{token}         // Temporary activation tokens
```

## State Management

### AuthProvider State

```dart
// General states
bool _isLoading                        // Loading indicator
String? _errorMessage                  // Contextual error messages
RegistrationStep _currentStep          // Current registration step

// Registration-specific states
Map<String, dynamic>? _verifiedLicenseData  // Verified license information
String? _pendingLicenseId              // License ID awaiting completion
String? _pendingEmail                  // Email awaiting completion

// Initialization tracking
bool _hasReceivedAuthState             // Firebase Auth initialization status
StreamSubscription? _authStateSub      // Auth state change listener
```

### Reactive UI

- **Real-time updates**: UI automatically responds to state changes
- **Loading states**: Visual feedback during async operations
- **Error recovery**: Contextual error messages with recovery options
- **Smooth transitions**: AnimatedSwitcher for registration steps

## Integration with Other Features

### Voting Feature Integration

```dart
// VoteProvider depends on AuthProvider for user authentication
import '../../auth/index.dart';

// VoteService uses Firebase Auth for current user
final currentUser = FirebaseAuth.instance.currentUser;
```

### Navigation Integration

```dart
// Main app navigation with auth protection
'/home': (context) => RequireAuth(child: const HomePage()),
'/profile': (context) => RequireAuth(child: const ProfilePage()),
```

## Development Features

### Emulator Support

- **Automatic configuration**: Debug mode connects to Firebase emulators
- **Clean sessions**: Automatic session cleanup in emulator mode
- **Network diagnostics**: Connection testing for better error messages

### Error Handling

- **Contextual errors**: Different error messages per registration step
- **Recovery mechanisms**: Smart error recovery and step navigation
- **User-friendly messages**: Translated error messages for better UX

## Security Features

### Email Uniqueness

- **Reservation system**: Firestore transactions prevent duplicate emails
- **Rollback mechanism**: Failed operations clean up reservations

### Token Validation

- **Server-side validation**: All tokens validated via Cloud Functions
- **Time-limited tokens**: Activation tokens have expiration
- **Secure transmission**: Tokens sent via email, validated server-side

### License Verification

- **Official registry**: License verification against official arbitrator registry
- **Real-time validation**: Server-side license status checking
- **Fraud prevention**: Multiple validation layers

## Usage Examples

```dart
// Protect a route
RequireAuth(child: const HomePage())

// Access authentication state
Consumer<AuthProvider>(
  builder: (context, auth, child) {
    if (auth.isAuthenticated) {
      return ProfileWidget();
    }
    return LoginPrompt();
  },
)

// Trigger login
await context.read<AuthProvider>().signIn(email, password);

// Complete registration
await context.read<AuthProvider>().completeRegistrationProcess(password);
```

This authentication system provides **enterprise-grade security** with a **user-friendly interface**, supporting complex registration workflows while maintaining **clean architecture** and **scalable code organization**! 🔐
