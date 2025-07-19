# Domain-Driven Design Implementation in OWASP Note

This project demonstrates a comprehensive Domain-Driven Design (DDD) implementation in Flutter, showcasing best practices and patterns for building secure, maintainable applications.

## Architecture Overview

The implementation follows a layered architecture with clear separation of concerns:

```
lib/
├── domain/           # Core business logic and rules
├── application/      # Application services and use cases
├── infrastructure/   # External concerns (DB, services)
└── presentation/     # UI layer (existing screens)
```

## Domain Layer

### Core Building Blocks

1. **Entity** (`domain/core/entity.dart`)
   - Base class for all entities
   - Identity-based equality

2. **Value Object** (`domain/core/value_object.dart`)
   - Immutable objects without identity
   - Self-validating with Either monad for error handling

3. **Aggregate Root** (`domain/core/aggregate_root.dart`)
   - Entry point to aggregate
   - Manages domain events
   - Ensures consistency boundaries

4. **Domain Events** (`domain/core/domain_event.dart`)
   - Capture important state changes
   - Enable event-driven architecture

5. **Repository** (`domain/core/repository.dart`)
   - Abstract interface for persistence
   - Domain-focused operations

6. **Specification** (`domain/core/specification.dart`)
   - Encapsulate business rules
   - Composable with and/or/not operations

### Domain Aggregates

#### Note Aggregate
- **Root**: `Note` class with rich domain logic
- **Value Objects**: `NoteId`, `NoteTitle`, `NoteContent`
- **Invariants**:
  - Title must be 1-100 characters
  - Content max 10,000 characters
  - Cannot share with yourself
  - Cannot modify deleted notes
- **Domain Events**: Created, Updated, Shared, Deleted, etc.

#### User Aggregate
- **Root**: `User` class with authentication logic
- **Value Objects**: `UserId`, `Email`, `Username`, `Password`
- **Invariants**:
  - Strong password requirements
  - Email format validation
  - Username constraints
  - Account locking after failed attempts
- **Domain Events**: Registered, LoggedIn, PasswordChanged, etc.

### Domain Services

1. **AuthenticationService**
   - Complex authentication logic
   - Two-factor authentication
   - Password change workflows

2. **NoteSharingService**
   - Orchestrate note sharing between users
   - Bulk operations
   - Permission validation

3. **PasswordHasher** (interface)
   - Abstract password hashing

4. **EncryptionService** (interface)
   - Abstract encryption operations

## Application Layer

Application services orchestrate domain logic and coordinate between aggregates:

### NoteApplicationService
- Create, update, delete notes
- Handle encryption/decryption
- Search and list operations
- Sharing workflows

### UserApplicationService
- User registration
- Authentication flows
- Profile management
- Administrative operations

## Infrastructure Layer

Concrete implementations of domain interfaces:

### Repositories
- `SqliteNoteRepository`: SQLite persistence for notes
- `SqliteUserRepository`: SQLite persistence for users

### Services
- `CryptoPasswordHasher`: PBKDF2 password hashing
- `AesEncryptionService`: AES-256 encryption

## Key DDD Patterns Demonstrated

### 1. Ubiquitous Language
The code uses domain-specific terminology:
- Users "register" and "login"
- Notes are "shared" and "encrypted"
- Accounts can be "locked" and "verified"

### 2. Bounded Contexts
Clear boundaries between:
- User/Authentication context
- Note/Content management context

### 3. Aggregate Design
- Small, focused aggregates
- Clear consistency boundaries
- Root entities protect invariants

### 4. Value Objects
- Self-validating
- Immutable
- Express domain concepts (not just strings)

### 5. Domain Events
- Capture business-meaningful occurrences
- Enable audit trails
- Support eventual consistency

### 6. Specifications
- Encapsulate complex queries
- Reusable business rules
- Composable for flexibility

## Usage Examples

### Creating a Note
```dart
final noteService = NoteApplicationService(/*dependencies*/);
final result = await noteService.createNote(
  userId: currentUser.id,
  title: "Security Best Practices",
  content: "Always use HTTPS...",
  encrypt: true,
  tags: ["security", "owasp"],
);

if (result.isSuccess) {
  print("Note created with ID: ${result.note!.id.value}");
  print("Encryption key: ${result.encryptionKey}");
}
```

### User Registration
```dart
final userService = UserApplicationService(/*dependencies*/);
final result = await userService.registerUser(
  email: "user@example.com",
  username: "secureuser",
  password: "MyStr0ng!Password123",
);

if (result.isSuccess) {
  print("User registered: ${result.user!.id.value}");
}
```

### Complex Queries with Specifications
```dart
// Find all encrypted notes shared with a user created in last 30 days
final spec = NoteEncryptedSpecification()
  .and(NoteSharedWithUserSpecification(userId))
  .and(NoteCreatedAfterSpecification(
    DateTime.now().subtract(Duration(days: 30))
  ));

final notes = allNotes.where((note) => spec.isSatisfiedBy(note)).toList();
```

## Security Considerations

The DDD implementation enhances security through:

1. **Strong Typing**: Value objects prevent injection attacks
2. **Invariant Protection**: Business rules enforced at domain level
3. **Encapsulation**: Aggregates hide internal state
4. **Validation**: Self-validating value objects
5. **Event Sourcing Ready**: Domain events enable audit trails

## Testing Strategy

The DDD structure enables comprehensive testing:

1. **Unit Tests**: Test domain logic in isolation
2. **Integration Tests**: Test application services
3. **Specification Tests**: Verify business rules
4. **Repository Tests**: Test persistence layer

## Benefits of This Approach

1. **Maintainability**: Clear separation of concerns
2. **Testability**: Business logic isolated from infrastructure
3. **Flexibility**: Easy to change persistence or UI
4. **Security**: Domain invariants prevent invalid states
5. **Scalability**: Event-driven architecture ready
6. **Documentation**: Code expresses business rules clearly

## Next Steps

To integrate this DDD implementation:

1. Replace existing models with domain entities
2. Update services to use application services
3. Implement event handlers for domain events
4. Add unit tests for domain logic
5. Migrate existing SQLite code to repositories

This implementation provides a solid foundation for building secure, maintainable Flutter applications following Domain-Driven Design principles.