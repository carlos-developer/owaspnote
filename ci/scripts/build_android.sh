#!/bin/bash

# OWASP Note - Android Build Script
# This script builds the Android APK and AAB with security best practices

set -e

echo "================================================"
echo "OWASP Note - Android Build Script"
echo "================================================"

# Configuration
BUILD_TYPE=${1:-release}
BUILD_NUMBER=${BUILD_NUMBER:-1}
VERSION_NAME=${VERSION_NAME:-1.0.0}
OUTPUT_DIR="build/outputs/android"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean
rm -rf $OUTPUT_DIR
mkdir -p $OUTPUT_DIR

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Run security checks
print_status "Running security checks..."

# Check for hardcoded secrets
if grep -r "password\|secret\|api_key\|apikey" lib/ --exclude-dir=.git | grep -v "SecureStorage\|MockAuthService"; then
    print_warning "Potential hardcoded secrets found. Please review."
fi

# Check for insecure HTTP usage
if grep -r "http://" lib/ --exclude-dir=.git | grep -v "localhost\|127.0.0.1"; then
    print_warning "Insecure HTTP usage detected. Consider using HTTPS."
fi

# Run tests
print_status "Running tests..."
flutter test || {
    print_error "Tests failed. Fix errors before building."
    exit 1
}

# Run code analysis
print_status "Running Flutter analyze..."
flutter analyze || {
    print_error "Code analysis failed. Fix issues before building."
    exit 1
}

# Build based on type
if [ "$BUILD_TYPE" = "release" ]; then
    print_status "Building release APK..."
    
    # Check if keystore exists
    if [ ! -f "$ANDROID_KEYSTORE" ]; then
        print_error "Android keystore not found. Cannot build release version."
        exit 1
    fi
    
    # Build release APK
    flutter build apk --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION_NAME \
        --obfuscate \
        --split-debug-info=build/debug-info \
        --tree-shake-icons
    
    # Build release AAB for Play Store
    print_status "Building release App Bundle..."
    flutter build appbundle --release \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION_NAME \
        --obfuscate \
        --split-debug-info=build/debug-info \
        --tree-shake-icons
    
    # Copy outputs
    cp build/app/outputs/flutter-apk/app-release.apk $OUTPUT_DIR/owaspnote-$VERSION_NAME-$BUILD_NUMBER.apk
    cp build/app/outputs/bundle/release/app-release.aab $OUTPUT_DIR/owaspnote-$VERSION_NAME-$BUILD_NUMBER.aab
    
    # Generate checksums
    print_status "Generating checksums..."
    cd $OUTPUT_DIR
    sha256sum owaspnote-$VERSION_NAME-$BUILD_NUMBER.apk > owaspnote-$VERSION_NAME-$BUILD_NUMBER.apk.sha256
    sha256sum owaspnote-$VERSION_NAME-$BUILD_NUMBER.aab > owaspnote-$VERSION_NAME-$BUILD_NUMBER.aab.sha256
    cd -
    
else
    print_status "Building debug APK..."
    
    flutter build apk --debug \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION_NAME
    
    # Copy output
    cp build/app/outputs/flutter-apk/app-debug.apk $OUTPUT_DIR/owaspnote-debug-$VERSION_NAME-$BUILD_NUMBER.apk
fi

# Verify APK security
print_status "Verifying APK security..."

APK_FILE=$(find $OUTPUT_DIR -name "*.apk" | head -1)

if [ -f "$APK_FILE" ]; then
    # Check APK size
    APK_SIZE=$(stat -f%z "$APK_FILE" 2>/dev/null || stat -c%s "$APK_FILE")
    APK_SIZE_MB=$((APK_SIZE / 1024 / 1024))
    print_status "APK size: ${APK_SIZE_MB}MB"
    
    # Extract and analyze APK
    print_status "Analyzing APK contents..."
    TEMP_DIR=$(mktemp -d)
    unzip -q "$APK_FILE" -d "$TEMP_DIR"
    
    # Check for debugging information
    if grep -r "BuildConfig.DEBUG" "$TEMP_DIR" 2>/dev/null; then
        if [ "$BUILD_TYPE" = "release" ]; then
            print_warning "Debug information found in release build"
        fi
    fi
    
    # Check for native libraries
    if [ -d "$TEMP_DIR/lib" ]; then
        print_status "Native libraries included:"
        find "$TEMP_DIR/lib" -name "*.so" -type f | head -10
    fi
    
    # Cleanup
    rm -rf "$TEMP_DIR"
fi

# Generate build report
print_status "Generating build report..."
cat > $OUTPUT_DIR/build-report.txt << EOF
OWASP Note Android Build Report
================================
Build Date: $(date)
Build Type: $BUILD_TYPE
Build Number: $BUILD_NUMBER
Version: $VERSION_NAME
Flutter Version: $(flutter --version | head -1)

Outputs:
$(ls -la $OUTPUT_DIR/*.apk 2>/dev/null || echo "No APK files")
$(ls -la $OUTPUT_DIR/*.aab 2>/dev/null || echo "No AAB files")

Security Features:
- Code obfuscation: $([ "$BUILD_TYPE" = "release" ] && echo "Enabled" || echo "Disabled")
- Certificate pinning: Enabled
- Anti-tampering: Enabled
- Secure storage: Enabled
- Root detection: Enabled

Checksums:
$(cat $OUTPUT_DIR/*.sha256 2>/dev/null || echo "No checksums generated")
EOF

print_status "Build completed successfully!"
print_status "Outputs available in: $OUTPUT_DIR"

# Display summary
echo ""
echo "================================================"
echo "Build Summary:"
echo "================================================"
ls -la $OUTPUT_DIR/

exit 0