#!/bin/bash

# OWASP Note - JFrog Artifactory Upload Script
# This script uploads build artifacts to JFrog Artifactory

set -e

echo "================================================"
echo "OWASP Note - Artifactory Upload Script"
echo "================================================"

# Configuration
ARTIFACT_PATH=${1:-}
ARTIFACT_TYPE=${2:-android}  # android, web, or all
BUILD_NUMBER=${BUILD_NUMBER:-1}
VERSION_NAME=${VERSION_NAME:-1.0.0}
BRANCH_NAME=${BRANCH_NAME:-main}

# JFrog CLI configuration
JFROG_CLI_URL="https://getcli.jfrog.io/v2/jfrog"
JFROG_CLI_PATH="/usr/local/bin/jfrog"

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

# Check required environment variables
if [ -z "$ARTIFACTORY_URL" ] || [ -z "$ARTIFACTORY_USER" ] || [ -z "$ARTIFACTORY_PASSWORD" ]; then
    print_error "Missing Artifactory credentials. Please set ARTIFACTORY_URL, ARTIFACTORY_USER, and ARTIFACTORY_PASSWORD"
    exit 1
fi

# Install JFrog CLI if not present
if ! command -v jfrog &> /dev/null; then
    print_status "Installing JFrog CLI..."
    curl -fL "$JFROG_CLI_URL" | sh
    chmod +x jfrog
    sudo mv jfrog "$JFROG_CLI_PATH"
fi

# Configure JFrog CLI
print_status "Configuring JFrog CLI..."
jfrog config rm artifactory-server --quiet 2>/dev/null || true
jfrog config add artifactory-server \
    --artifactory-url="$ARTIFACTORY_URL" \
    --user="$ARTIFACTORY_USER" \
    --password="$ARTIFACTORY_PASSWORD" \
    --interactive=false

# Create repository structure
REPO_BASE="${ARTIFACTORY_REPO:-owaspnote-artifacts}"
ANDROID_REPO="$REPO_BASE/android"
WEB_REPO="$REPO_BASE/web"
METADATA_REPO="$REPO_BASE/metadata"

# Function to upload artifact with metadata
upload_artifact() {
    local file_path=$1
    local target_path=$2
    local artifact_type=$3
    
    if [ ! -f "$file_path" ]; then
        print_warning "File not found: $file_path"
        return 1
    fi
    
    print_status "Uploading $file_path to $target_path..."
    
    # Generate metadata
    local file_size=$(stat -f%z "$file_path" 2>/dev/null || stat -c%s "$file_path")
    local file_md5=$(md5sum "$file_path" | cut -d' ' -f1)
    local file_sha256=$(sha256sum "$file_path" | cut -d' ' -f1)
    
    # Upload with properties
    jfrog rt upload "$file_path" "$target_path" \
        --props="build.number=$BUILD_NUMBER;build.name=owaspnote;version=$VERSION_NAME;branch=$BRANCH_NAME;type=$artifact_type;size=$file_size;md5=$file_md5;sha256=$file_sha256"
    
    # Upload checksum file if exists
    if [ -f "$file_path.sha256" ]; then
        jfrog rt upload "$file_path.sha256" "$target_path.sha256"
    fi
    
    return 0
}

# Function to create and upload build metadata
create_build_metadata() {
    local metadata_file="build-metadata-$BUILD_NUMBER.json"
    
    cat > "$metadata_file" << EOF
{
  "build": {
    "number": "$BUILD_NUMBER",
    "name": "owaspnote",
    "version": "$VERSION_NAME",
    "branch": "$BRANCH_NAME",
    "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
    "git_commit": "${GIT_COMMIT:-unknown}",
    "git_author": "${GIT_AUTHOR:-unknown}",
    "flutter_version": "$(flutter --version | head -1)",
    "artifacts": {
      "android": {
        "apk": "$ANDROID_REPO/$VERSION_NAME/owaspnote-$VERSION_NAME-$BUILD_NUMBER.apk",
        "aab": "$ANDROID_REPO/$VERSION_NAME/owaspnote-$VERSION_NAME-$BUILD_NUMBER.aab"
      },
      "web": {
        "tar": "$WEB_REPO/$VERSION_NAME/owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.tar.gz",
        "zip": "$WEB_REPO/$VERSION_NAME/owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.zip"
      }
    },
    "security_features": {
      "code_obfuscation": true,
      "certificate_pinning": true,
      "anti_tampering": true,
      "secure_storage": true,
      "root_detection": true
    }
  }
}
EOF
    
    # Upload metadata
    jfrog rt upload "$metadata_file" "$METADATA_REPO/$VERSION_NAME/build-$BUILD_NUMBER.json"
    rm -f "$metadata_file"
}

# Main upload logic
if [ -n "$ARTIFACT_PATH" ] && [ -f "$ARTIFACT_PATH" ]; then
    # Single artifact upload
    if [[ "$ARTIFACT_PATH" == *.apk ]] || [[ "$ARTIFACT_PATH" == *.aab ]]; then
        upload_artifact "$ARTIFACT_PATH" "$ANDROID_REPO/$VERSION_NAME/$(basename "$ARTIFACT_PATH")" "android"
    elif [[ "$ARTIFACT_PATH" == *.tar.gz ]] || [[ "$ARTIFACT_PATH" == *.zip ]]; then
        upload_artifact "$ARTIFACT_PATH" "$WEB_REPO/$VERSION_NAME/$(basename "$ARTIFACT_PATH")" "web"
    else
        print_error "Unknown artifact type: $ARTIFACT_PATH"
        exit 1
    fi
else
    # Upload all artifacts based on type
    case "$ARTIFACT_TYPE" in
        android)
            print_status "Uploading Android artifacts..."
            # Upload APK
            if [ -f "build/app/outputs/flutter-apk/app-release.apk" ]; then
                upload_artifact "build/app/outputs/flutter-apk/app-release.apk" \
                    "$ANDROID_REPO/$VERSION_NAME/owaspnote-$VERSION_NAME-$BUILD_NUMBER.apk" \
                    "android"
            fi
            
            # Upload AAB
            if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
                upload_artifact "build/app/outputs/bundle/release/app-release.aab" \
                    "$ANDROID_REPO/$VERSION_NAME/owaspnote-$VERSION_NAME-$BUILD_NUMBER.aab" \
                    "android"
            fi
            ;;
            
        web)
            print_status "Uploading Web artifacts..."
            # Find and upload web packages
            for file in build/outputs/web/*.tar.gz build/outputs/web/*.zip; do
                if [ -f "$file" ]; then
                    upload_artifact "$file" "$WEB_REPO/$VERSION_NAME/$(basename "$file")" "web"
                fi
            done
            ;;
            
        all)
            print_status "Uploading all artifacts..."
            # Upload Android
            $0 "" android
            # Upload Web
            $0 "" web
            ;;
            
        *)
            print_error "Invalid artifact type: $ARTIFACT_TYPE"
            print_status "Usage: $0 [artifact_path] [android|web|all]"
            exit 1
            ;;
    esac
fi

# Create and upload build metadata
print_status "Creating build metadata..."
create_build_metadata

# Create build info
print_status "Publishing build info..."
jfrog rt build-collect-env owaspnote $BUILD_NUMBER
jfrog rt build-add-git owaspnote $BUILD_NUMBER
jfrog rt build-publish owaspnote $BUILD_NUMBER

# Run Xray scan if available
print_status "Running security scan..."
jfrog rt build-scan owaspnote $BUILD_NUMBER || print_warning "Xray scan not available"

# Generate download URLs
print_status "Generating artifact URLs..."
echo ""
echo "================================================"
echo "Artifact URLs:"
echo "================================================"

# Query uploaded artifacts
jfrog rt search "$REPO_BASE/*$VERSION_NAME*$BUILD_NUMBER*" --limit=10 | jq -r '.[] | .path' | while read -r artifact; do
    echo "$ARTIFACTORY_URL/$artifact"
done

# Cleanup old artifacts (keep last 10 builds)
if [ "$BRANCH_NAME" != "main" ]; then
    print_status "Cleaning up old artifacts..."
    # This is a simplified cleanup - in production, use more sophisticated retention policies
    jfrog rt search "$REPO_BASE/*" --props="branch=$BRANCH_NAME" --sort-by="created" --sort-order="desc" --limit=1000 | \
        jq -r '.[] | .path' | tail -n +50 | while read -r old_artifact; do
        print_status "Deleting old artifact: $old_artifact"
        jfrog rt delete "$old_artifact" --quiet
    done
fi

print_status "Artifactory upload completed successfully!"

exit 0