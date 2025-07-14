# Testing Guide - OWASP Note

## Overview

The OWASP Note project includes comprehensive testing covering unit tests and integration tests to ensure security and functionality.

## Test Structure

```
owaspnote/
├── test/                       # Unit tests
│   ├── integration/           # Integration-style unit tests
│   ├── models/               # Model tests
│   ├── security/             # Security configuration tests
│   └── widgets/              # Widget tests
├── integration_test/          # Flutter integration tests
│   ├── app_test.dart         # Basic app startup test
│   ├── auth_flow_test.dart   # Authentication flow tests
│   ├── security_integration_test.dart  # Security feature tests
│   └── user_registration_authentication_e2e_test.dart  # E2E tests
└── test_driver/              # Test driver for integration tests
    └── integration_test.dart

```

## Running Tests

### Quick Start

```bash
# Run all tests (unit + integration if device available)
./run_all_tests.sh

# Run only integration tests
./run_integration_tests.sh

# Run specific test file
flutter test test/widget_test.dart
```

### Unit Tests

Run unit tests without needing a device:

```bash
# Run all unit tests
flutter test

# Run specific test directory
flutter test test/security/

# Run with coverage
flutter test --coverage
```

### Integration Tests

Integration tests require a connected device or emulator:

```bash
# Check available devices
flutter devices

# Run all integration tests
flutter test integration_test/

# Run specific integration test
flutter test integration_test/auth_flow_test.dart

# Run with extended timeout
flutter test integration_test/ --timeout 5m
```

### Running on Different Platforms

#### Android Device/Emulator
```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch <emulator_id>

# Run tests
flutter test integration_test/ -d <device_id>
```

#### Physical Device
1. Connect device via USB
2. Enable Developer Mode on device
3. Authorize computer for debugging
4. Run: `flutter test integration_test/`

## Test Categories

### Security Tests
- **SQL Injection Protection**: Tests input sanitization
- **XSS Prevention**: Validates HTML/script filtering
- **Password Strength**: Ensures strong password requirements
- **Encryption**: Verifies AES-256 encryption
- **Session Management**: Tests secure session handling

### Functional Tests
- **User Registration**: Complete registration flow
- **Authentication**: Login/logout functionality
- **Note Management**: CRUD operations on notes
- **Navigation**: Screen transitions and routing

### Performance Tests
- **Load Testing**: Multiple rapid operations
- **Memory Management**: Resource cleanup
- **Response Times**: UI responsiveness

## Writing New Tests

### Unit Test Template
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Feature Name', () {
    setUp(() {
      // Setup before each test
    });

    tearDown(() {
      // Cleanup after each test
    });

    test('should do something', () {
      // Arrange
      final input = 'test';
      
      // Act
      final result = someFunction(input);
      
      // Assert
      expect(result, equals('expected'));
    });
  });
}
```

### Integration Test Template
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owaspnote/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Integration Tests', () {
    testWidgets('test description', (tester) async {
      // Start app
      await tester.pumpWidget(const SecureNotesApp());
      await tester.pumpAndSettle();

      // Interact with UI
      await tester.tap(find.text('Button'));
      await tester.pumpAndSettle();

      // Verify results
      expect(find.text('Expected'), findsOneWidget);
    });
  });
}
```

## Troubleshooting

### Common Issues

1. **Tests Timing Out**
   - Increase timeout: `--timeout 5m`
   - Run tests individually
   - Check device performance

2. **Build Failures**
   ```bash
   flutter clean
   flutter pub get
   ```

3. **Device Not Found**
   - Check USB connection
   - Verify developer mode enabled
   - Run `adb devices` (Android)

4. **Mock Data Issues**
   - Ensure `AuthService.enableMockMode()` is called
   - Clear data between tests

### Debug Mode

For verbose output:
```bash
flutter test --verbose
```

For specific test debugging:
```bash
flutter test --name "test name"
```

## CI/CD Integration

For continuous integration:

```yaml
# Example GitHub Actions
test:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
    - run: flutter pub get
    - run: flutter test
    - run: flutter test --coverage
```

## Best Practices

1. **Always Clean State**: Use setUp/tearDown
2. **Mock External Services**: Use test doubles
3. **Test Security Features**: Validate all OWASP mitigations
4. **Keep Tests Fast**: Mock heavy operations
5. **Test Edge Cases**: Include boundary conditions
6. **Document Tests**: Clear test names and comments