# Web Integration Tests for OWASP Note

This guide explains how to run integration tests for OWASP Note on web browsers using Chrome.

## Prerequisites

1. **Flutter SDK** - Ensure Flutter is installed and configured for web development
2. **Chrome Browser** - Must have Google Chrome installed
3. **ChromeDriver** - Required for automated browser testing
4. **Node.js & npm** (optional) - For automatic ChromeDriver installation

## Installing ChromeDriver

### Option 1: Automatic Installation (Recommended)

```bash
# Using npx (requires Node.js)
npx @puppeteer/browsers install chromedriver@stable
```

### Option 2: Manual Installation

1. Download ChromeDriver from https://chromedriver.chromium.org/downloads
2. Choose the version that matches your Chrome browser version
3. Extract and add to your system PATH

### Verify Installation

```bash
chromedriver --version
```

## Running Web Integration Tests

### Quick Start

```bash
# Run all integration tests on Chrome
./run_integration_tests.sh --web

# Run in headless mode (no browser window)
./run_integration_tests.sh --web --headless
```

### Manual Execution

If you prefer to run tests manually:

1. **Start ChromeDriver**
   ```bash
   chromedriver --port=4444
   ```

2. **In another terminal, run tests**
   ```bash
   # Run specific test
   flutter drive \
     --driver=test_driver/integration_test.dart \
     --target=integration_test/app_test.dart \
     -d chrome

   # Run in headless mode
   flutter drive \
     --driver=test_driver/integration_test.dart \
     --target=integration_test/app_test.dart \
     -d web-server
   ```

## Script Features

The `run_integration_tests_web.sh` script provides:

- Automatic ChromeDriver detection and installation
- ChromeDriver lifecycle management
- Support for both headed and headless modes
- Individual test execution to avoid timeouts
- Detailed test results and summary

## Troubleshooting

### ChromeDriver Issues

**Problem**: ChromeDriver version mismatch
```bash
# Check Chrome version
google-chrome --version

# Download matching ChromeDriver version
# Visit: https://chromedriver.chromium.org/downloads
```

**Problem**: ChromeDriver not in PATH
```bash
# Add to PATH (Linux/Mac)
export PATH=$PATH:/path/to/chromedriver

# Or move to system bin
sudo mv chromedriver /usr/local/bin/
```

### Test Failures

**Problem**: Tests timing out
```bash
# Increase timeout in flutter drive command
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart \
  -d chrome \
  --timeout=600
```

**Problem**: Port already in use
```bash
# Kill existing ChromeDriver process
pkill chromedriver

# Or use a different port
chromedriver --port=9515
```

### Web-Specific Considerations

1. **Browser Security**: Some security features may behave differently in web
2. **Local Storage**: Web uses browser storage instead of app storage
3. **Permissions**: Browser permissions work differently than mobile
4. **Performance**: Web tests may run slower than native tests

## Writing Web-Compatible Tests

When writing integration tests for web:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Web-compatible test', (tester) async {
    // Avoid platform-specific code
    // Use conditional imports for platform differences
    // Test responsive layouts
  });
}
```

## CI/CD Integration

For CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Install ChromeDriver
  run: |
    npm install -g chromedriver
    
- name: Run Web Integration Tests
  run: |
    chromedriver --port=4444 &
    sleep 2
    flutter drive \
      --driver=test_driver/integration_test.dart \
      --target=integration_test/ \
      -d web-server
```

## Best Practices

1. **Run tests regularly** - Include in your development workflow
2. **Test on multiple browsers** - Chrome, Firefox, Safari
3. **Check responsive design** - Test different viewport sizes
4. **Monitor performance** - Web tests can identify performance issues
5. **Use headless mode in CI** - Faster and more reliable

## Additional Resources

- [Flutter Web Testing Documentation](https://docs.flutter.dev/testing/integration-tests)
- [ChromeDriver Documentation](https://chromedriver.chromium.org/)
- [Flutter Web Development](https://flutter.dev/web)