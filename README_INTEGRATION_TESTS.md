# Running Integration Tests for OWASP Note

This document explains how to properly run integration tests for the OWASP Note application.

## Integration Test Structure

The project has integration tests in the following locations:
- `/integration_test/` - Flutter integration tests that require a device/emulator
- `/test/integration/` - Unit tests with integration characteristics

## Prerequisites

1. Have Flutter installed and configured
2. Have a physical device connected or an emulator running
3. Ensure the device is authorized for development

## Running Integration Tests

### Method 1: Run on Web Browser (Chrome)

```bash
# Run all tests on Chrome
./run_integration_tests.sh --web

# Run in headless mode
./run_integration_tests.sh --web --headless

# Or use the dedicated web script
./run_integration_tests_web.sh
```

See [WEB_INTEGRATION_TESTS.md](WEB_INTEGRATION_TESTS.md) for detailed web testing instructions.

### Method 2: Run on Physical Device (Recommended for mobile)

```bash
# Check available devices
flutter devices

# Run a specific integration test
flutter test integration_test/app_test.dart

# Run all integration tests
flutter test integration_test/
```

### Method 2: Run with Android Emulator

```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run integration tests
flutter test integration_test/
```

### Method 4: Run as Unit Tests

For tests in the `/test/integration/` folder:

```bash
# Run specific test
flutter test test/integration/user_registration_authentication_test.dart

# Run all tests
flutter test
```

## Troubleshooting

### Tests Timing Out

If tests are timing out, try:

1. Increase timeout:
```bash
flutter test integration_test/ --timeout 5m
```

2. Run tests individually:
```bash
flutter test integration_test/auth_flow_test.dart
flutter test integration_test/security_integration_test.dart
```

3. Check device connection:
```bash
adb devices  # For Android
flutter doctor -v
```

### Build Issues

If you encounter build issues:

```bash
# Clean the project
flutter clean

# Get dependencies
flutter pub get

# Try running again
flutter test integration_test/
```

### Running Tests in CI/CD

For CI/CD environments, use:

```bash
# Run with no sound null safety (if needed)
flutter test integration_test/ --no-sound-null-safety

# Run with specific device
flutter test integration_test/ -d <device_id>
```

## Test Coverage

The integration tests cover:
- User registration flow
- Authentication flow
- Security validations (OWASP Mobile Top 10)
- Note creation and management
- Session management

## Writing New Integration Tests

Place new integration tests in `/integration_test/` with the naming convention `*_test.dart`.

Example structure:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:owaspnote/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feature Tests', () {
    testWidgets('test description', (tester) async {
      // Test implementation
    });
  });
}
```