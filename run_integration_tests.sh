#!/bin/bash

# Script to run OWASP Note integration tests

echo "🚀 Starting OWASP Note Integration Tests..."
echo "==========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed or not in PATH${NC}"
    exit 1
fi

# Check Flutter doctor
echo -e "${YELLOW}📋 Checking Flutter environment...${NC}"
flutter doctor -v

# Check connected devices
echo -e "\n${YELLOW}📱 Checking connected devices...${NC}"
flutter devices

# Clean and get dependencies
echo -e "\n${YELLOW}🧹 Cleaning project...${NC}"
flutter clean

echo -e "\n${YELLOW}📦 Getting dependencies...${NC}"
flutter pub get

# Run unit tests first
echo -e "\n${YELLOW}🧪 Running unit tests...${NC}"
flutter test --no-pub

# Run integration tests
echo -e "\n${YELLOW}🔄 Running integration tests...${NC}"

# Check if there's a connected device
if flutter devices | grep -q "connected device"; then
    echo -e "${GREEN}✅ Device found, running integration tests...${NC}"
    
    # Run each integration test file separately to avoid timeouts
    for test_file in integration_test/*_test.dart; do
        if [ -f "$test_file" ]; then
            echo -e "\n${YELLOW}Running: $test_file${NC}"
            flutter test "$test_file" --timeout 3m
            
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}✅ $test_file passed${NC}"
            else
                echo -e "${RED}❌ $test_file failed${NC}"
            fi
        fi
    done
else
    echo -e "${RED}❌ No device connected. Please connect a device or start an emulator.${NC}"
    echo -e "${YELLOW}Run 'flutter emulators' to see available emulators${NC}"
    echo -e "${YELLOW}Run 'flutter emulators --launch <emulator_id>' to start an emulator${NC}"
    exit 1
fi

echo -e "\n${GREEN}✅ Integration tests completed!${NC}"