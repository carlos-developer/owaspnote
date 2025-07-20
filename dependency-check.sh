#!/bin/bash

# OWASP Dependency-Check Script for Flutter Project
# This script runs dependency-check on the Flutter project and generates an HTML report

PROJECT_NAME="owaspnote"
REPORT_DIR="./dependency-check-report"
DC_VERSION="9.0.9"

echo "=== OWASP Dependency-Check for $PROJECT_NAME ==="
echo ""

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Option 1: Using Docker (Recommended - no installation required)
if command -v docker &> /dev/null; then
    echo "Docker found. Running Dependency-Check using Docker..."
    
    docker run --rm \
        -v "$(pwd)":/src \
        -v "$(pwd)/$REPORT_DIR":/report \
        owasp/dependency-check:latest \
        --scan /src \
        --format HTML \
        --format JSON \
        --project "$PROJECT_NAME" \
        --out /report \
        --enableExperimental \
        --disableAssembly \
        --prettyPrint
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Dependency-Check completed successfully!"
        echo "📄 HTML Report: $REPORT_DIR/dependency-check-report.html"
        echo "📄 JSON Report: $REPORT_DIR/dependency-check-report.json"
    else
        echo "❌ Error running Dependency-Check with Docker"
        exit 1
    fi
    
else
    echo "Docker not found. Please install Docker or use the manual installation method."
    echo ""
    echo "To install Docker:"
    echo "  - Ubuntu/Debian: sudo apt-get install docker.io"
    echo "  - Or visit: https://docs.docker.com/get-docker/"
    echo ""
    echo "Alternative: Download Dependency-Check manually:"
    echo "  wget https://github.com/jeremylong/DependencyCheck/releases/download/v$DC_VERSION/dependency-check-$DC_VERSION-release.zip"
    echo "  unzip dependency-check-$DC_VERSION-release.zip"
    echo "  ./dependency-check/bin/dependency-check.sh --scan . --format HTML --project $PROJECT_NAME --out $REPORT_DIR"
    exit 1
fi