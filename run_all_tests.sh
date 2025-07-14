#!/bin/bash

# Comprehensive test runner for OWASP Note project

echo "🚀 OWASP Note - Complete Test Suite"
echo "==================================="

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0

# Function to run tests and track results
run_test() {
    local test_name=$1
    local test_command=$2
    
    echo -e "\n${BLUE}Running: $test_name${NC}"
    echo "Command: $test_command"
    
    if eval "$test_command"; then
        echo -e "${GREEN}✅ $test_name PASSED${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $test_name FAILED${NC}"
        ((FAILED++))
    fi
}

# Clean and prepare
echo -e "${YELLOW}🧹 Preparing environment...${NC}"
flutter clean
flutter pub get

# Run unit tests
echo -e "\n${YELLOW}📝 UNIT TESTS${NC}"
echo "==============="

run_test "Widget Tests" "flutter test test/widget_test.dart"
run_test "Model Tests" "flutter test test/models/"
run_test "Security Config Tests" "flutter test test/security/"
run_test "Screen Tests" "flutter test test/widgets/"

# Run integration-style unit tests
echo -e "\n${YELLOW}🔗 INTEGRATION-STYLE UNIT TESTS${NC}"
echo "================================="

run_test "User Registration & Auth Test" "flutter test test/integration/user_registration_authentication_test.dart"

# Check for device and run real integration tests
echo -e "\n${YELLOW}📱 DEVICE INTEGRATION TESTS${NC}"
echo "============================="

if flutter devices | grep -q "connected device"; then
    echo -e "${GREEN}✅ Device detected${NC}"
    
    # Run each integration test with timeout
    for test_file in integration_test/*_test.dart; do
        if [ -f "$test_file" ]; then
            test_name=$(basename "$test_file" .dart)
            run_test "$test_name" "flutter test $test_file --timeout 2m"
        fi
    done
else
    echo -e "${YELLOW}⚠️  No device connected - Skipping device integration tests${NC}"
    echo "To run integration tests:"
    echo "  1. Connect a physical device, or"
    echo "  2. Start an emulator with: flutter emulators --launch <emulator_name>"
fi

# Summary
echo -e "\n${YELLOW}📊 TEST SUMMARY${NC}"
echo "================"
echo -e "Total tests run: $((PASSED + FAILED))"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"

if [ $FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed${NC}"
    exit 1
fi