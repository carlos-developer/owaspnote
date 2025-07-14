#!/bin/bash

# Script to run OWASP Note integration tests on Web with Chrome
# Based on https://docs.flutter.dev/testing/integration-tests

echo "🌐 Starting OWASP Note Web Integration Tests..."
echo "=============================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check if ChromeDriver is installed
echo -e "${YELLOW}🔍 Checking ChromeDriver installation...${NC}"
if ! command -v chromedriver &> /dev/null; then
    echo -e "${RED}❌ ChromeDriver is not installed or not in PATH${NC}"
    echo -e "${YELLOW}Installing ChromeDriver...${NC}"
    
    # Install ChromeDriver using npx
    if command -v npx &> /dev/null; then
        npx @puppeteer/browsers install chromedriver@stable
    else
        echo -e "${RED}❌ npx is not installed. Please install Node.js and npm first.${NC}"
        echo -e "${YELLOW}Alternatively, you can install ChromeDriver manually from:${NC}"
        echo -e "${BLUE}https://chromedriver.chromium.org/downloads${NC}"
        exit 1
    fi
fi

# Add ChromeDriver to PATH if found locally
CHROMEDRIVER_PATH=""
if [ -f "./chromedriver/linux-138.0.7204.94/chromedriver-linux64/chromedriver" ]; then
    CHROMEDRIVER_PATH="$(pwd)/chromedriver/linux-138.0.7204.94/chromedriver-linux64"
    export PATH="$PATH:$CHROMEDRIVER_PATH"
    echo -e "${GREEN}✅ Using local ChromeDriver at: $CHROMEDRIVER_PATH${NC}"
fi

# Verify ChromeDriver version
echo -e "${GREEN}✅ ChromeDriver found:${NC}"
chromedriver --version

# Clean and get dependencies
echo -e "\n${YELLOW}🧹 Cleaning project...${NC}"
flutter clean

echo -e "\n${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Start ChromeDriver
echo -e "\n${YELLOW}🚀 Starting ChromeDriver on port 4444...${NC}"
chromedriver --port=4444 &
CHROMEDRIVER_PID=$!

# Give ChromeDriver time to start
sleep 2

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🧹 Cleaning up...${NC}"
    if [ ! -z "$CHROMEDRIVER_PID" ]; then
        kill $CHROMEDRIVER_PID 2>/dev/null
        echo -e "${GREEN}✅ ChromeDriver stopped${NC}"
    fi
}

# Set trap to cleanup on script exit
trap cleanup EXIT

# Run integration tests on Chrome
echo -e "\n${YELLOW}🧪 Running integration tests on Chrome...${NC}"

# Check if we should run headless
if [ "$1" == "--headless" ]; then
    echo -e "${BLUE}Running in headless mode...${NC}"
    DEVICE="web-server"
else
    echo -e "${BLUE}Running with Chrome browser...${NC}"
    DEVICE="chrome"
fi

# Run each integration test file separately
FAILED_TESTS=0
PASSED_TESTS=0

for test_file in integration_test/*_test.dart; do
    if [ -f "$test_file" ]; then
        echo -e "\n${YELLOW}📋 Running: $test_file${NC}"
        
        flutter drive \
            --driver=test_driver/integration_test.dart \
            --target="$test_file" \
            -d "$DEVICE" \
            --web-port=8080 \
            --browser-name=chrome
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ $test_file passed${NC}"
            ((PASSED_TESTS++))
        else
            echo -e "${RED}❌ $test_file failed${NC}"
            ((FAILED_TESTS++))
        fi
    fi
done

# Summary
echo -e "\n${YELLOW}📊 Test Summary:${NC}"
echo -e "${GREEN}✅ Passed: $PASSED_TESTS${NC}"
echo -e "${RED}❌ Failed: $FAILED_TESTS${NC}"

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All web integration tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}❌ Some tests failed!${NC}"
    exit 1
fi