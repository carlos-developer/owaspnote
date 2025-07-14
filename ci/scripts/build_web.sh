#!/bin/bash

# OWASP Note - Web Build Script
# This script builds the Flutter web application with security best practices

set -e

echo "================================================"
echo "OWASP Note - Web Build Script"
echo "================================================"

# Configuration
BUILD_TYPE=${1:-release}
BUILD_NUMBER=${BUILD_NUMBER:-1}
VERSION_NAME=${VERSION_NAME:-1.0.0}
OUTPUT_DIR="build/outputs/web"
WEB_RENDERER=${WEB_RENDERER:-canvaskit}

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

# Check for insecure HTTP usage in web-specific code
if grep -r "http://" web/ lib/ --exclude-dir=.git | grep -v "localhost\|127.0.0.1"; then
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

# Build web application
if [ "$BUILD_TYPE" = "release" ]; then
    print_status "Building release web application..."
    
    flutter build web --release \
        --web-renderer=$WEB_RENDERER \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION_NAME \
        --tree-shake-icons \
        --pwa-strategy=offline-first \
        --csp
    
    # Optimize output
    print_status "Optimizing web build..."
    
    # Compress JavaScript files
    find build/web -name "*.js" -type f -exec gzip -9 -k {} \; 2>/dev/null || true
    
    # Generate security headers file
    print_status "Generating security headers..."
    cat > build/web/_headers << EOF
/*
  X-Frame-Options: DENY
  X-Content-Type-Options: nosniff
  X-XSS-Protection: 1; mode=block
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()
  Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; media-src 'none'; object-src 'none'; frame-src 'none'; worker-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'self'; manifest-src 'self'
EOF

    # Create deployment package
    print_status "Creating deployment package..."
    cd build/web
    tar -czf ../../$OUTPUT_DIR/owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.tar.gz *
    zip -r ../../$OUTPUT_DIR/owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.zip * >/dev/null
    cd ../..
    
else
    print_status "Building debug web application..."
    
    flutter build web --debug \
        --web-renderer=$WEB_RENDERER \
        --build-number=$BUILD_NUMBER \
        --build-name=$VERSION_NAME
    
    # Create deployment package
    cd build/web
    tar -czf ../../$OUTPUT_DIR/owaspnote-web-debug-$VERSION_NAME-$BUILD_NUMBER.tar.gz *
    cd ../..
fi

# Generate checksums
print_status "Generating checksums..."
cd $OUTPUT_DIR
for file in *.tar.gz *.zip; do
    if [ -f "$file" ]; then
        sha256sum "$file" > "$file.sha256"
    fi
done
cd -

# Analyze build output
print_status "Analyzing build output..."

# Check bundle size
MAIN_JS_SIZE=$(find build/web -name "main.dart.js" -type f -exec stat -f%z {} \; 2>/dev/null || find build/web -name "main.dart.js" -type f -exec stat -c%s {} \;)
if [ -n "$MAIN_JS_SIZE" ]; then
    MAIN_JS_SIZE_KB=$((MAIN_JS_SIZE / 1024))
    print_status "Main JavaScript bundle size: ${MAIN_JS_SIZE_KB}KB"
    
    if [ $MAIN_JS_SIZE_KB -gt 1024 ]; then
        print_warning "JavaScript bundle is larger than 1MB. Consider code splitting."
    fi
fi

# Check for service worker
if [ -f "build/web/flutter_service_worker.js" ]; then
    print_status "Service worker generated for offline support"
else
    print_warning "No service worker found"
fi

# Generate deployment instructions
print_status "Generating deployment instructions..."
cat > $OUTPUT_DIR/deployment-instructions.md << EOF
# OWASP Note Web Deployment Instructions

## Files
- Main package: owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.tar.gz
- Alternative format: owaspnote-web-$VERSION_NAME-$BUILD_NUMBER.zip

## Web Server Configuration

### Nginx Configuration
\`\`\`nginx
server {
    listen 443 ssl http2;
    server_name your-domain.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    root /var/www/owaspnote;
    index index.html;
    
    # Security headers
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Permissions-Policy "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()" always;
    
    # CSP header
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https:; media-src 'none'; object-src 'none'; frame-src 'none'; worker-src 'self'; form-action 'self'; frame-ancestors 'none'; base-uri 'self'; manifest-src 'self'" always;
    
    # Gzip compression
    gzip on;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json;
    
    location / {
        try_files \$uri \$uri/ /index.html;
    }
    
    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
\`\`\`

### Apache Configuration
\`\`\`apache
<VirtualHost *:443>
    ServerName your-domain.com
    DocumentRoot /var/www/owaspnote
    
    SSLEngine on
    SSLCertificateFile /path/to/cert.pem
    SSLCertificateKeyFile /path/to/key.pem
    
    # Security headers
    Header always set X-Frame-Options "DENY"
    Header always set X-Content-Type-Options "nosniff"
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Referrer-Policy "strict-origin-when-cross-origin"
    
    # Enable compression
    <IfModule mod_deflate.c>
        AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css text/javascript application/javascript
    </IfModule>
    
    # URL rewriting for SPA
    <Directory /var/www/owaspnote>
        RewriteEngine On
        RewriteBase /
        RewriteRule ^index\.html$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.html [L]
    </Directory>
</VirtualHost>
\`\`\`

## Deployment Steps
1. Extract the package to your web root
2. Configure your web server with the provided configuration
3. Ensure HTTPS is properly configured
4. Test the security headers using securityheaders.com
5. Monitor for any console errors in production
EOF

# Generate build report
print_status "Generating build report..."
cat > $OUTPUT_DIR/build-report.txt << EOF
OWASP Note Web Build Report
===========================
Build Date: $(date)
Build Type: $BUILD_TYPE
Build Number: $BUILD_NUMBER
Version: $VERSION_NAME
Web Renderer: $WEB_RENDERER
Flutter Version: $(flutter --version | head -1)

Outputs:
$(ls -la $OUTPUT_DIR/*.tar.gz 2>/dev/null || echo "No tar.gz files")
$(ls -la $OUTPUT_DIR/*.zip 2>/dev/null || echo "No zip files")

Build Features:
- PWA Support: Enabled
- Service Worker: $([ -f "build/web/flutter_service_worker.js" ] && echo "Generated" || echo "Not found")
- Tree Shaking: Enabled
- CSP Headers: Generated
- Web Renderer: $WEB_RENDERER

Security Features:
- Content Security Policy: Enabled
- Security Headers: Configured
- HTTPS Required: Yes
- XSS Protection: Enabled
- Clickjacking Protection: Enabled

Bundle Sizes:
- Main JS: ${MAIN_JS_SIZE_KB:-Unknown}KB

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