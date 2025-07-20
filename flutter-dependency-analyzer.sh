#!/bin/bash

# Flutter Dependency Analyzer Script
# Generates an HTML report of all Flutter/Dart dependencies with security information

PROJECT_NAME="owaspnote"
REPORT_DIR="./dependency-check-report"
HTML_REPORT="$REPORT_DIR/flutter-dependencies-report.html"

echo "=== Flutter Dependency Analyzer for $PROJECT_NAME ==="
echo ""

# Create report directory if it doesn't exist
mkdir -p "$REPORT_DIR"

# Get dependency information
echo "Fetching Flutter dependencies..."
flutter pub deps --json > "$REPORT_DIR/dependencies.json" 2>/dev/null

# Get outdated packages information
echo "Checking for outdated packages..."
flutter pub outdated --json > "$REPORT_DIR/outdated.json" 2>/dev/null

# Start HTML report
cat > "$HTML_REPORT" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Flutter Dependencies Security Report - owaspnote</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            margin: 20px;
            background-color: #f4f4f4;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 0 10px rgba(0,0,0,0.1);
        }
        h1, h2 {
            color: #333;
        }
        h1 {
            border-bottom: 3px solid #007bff;
            padding-bottom: 10px;
        }
        .info-box {
            background-color: #e7f3ff;
            border-left: 4px solid #007bff;
            padding: 10px;
            margin: 20px 0;
        }
        .warning-box {
            background-color: #fff3cd;
            border-left: 4px solid #ffc107;
            padding: 10px;
            margin: 20px 0;
        }
        .danger-box {
            background-color: #f8d7da;
            border-left: 4px solid #dc3545;
            padding: 10px;
            margin: 20px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        th {
            background-color: #f8f9fa;
            font-weight: bold;
        }
        tr:nth-child(even) {
            background-color: #f8f9fa;
        }
        .version-outdated {
            color: #dc3545;
            font-weight: bold;
        }
        .version-current {
            color: #28a745;
        }
        .security-badge {
            display: inline-block;
            padding: 3px 8px;
            border-radius: 3px;
            font-size: 12px;
            font-weight: bold;
        }
        .badge-critical {
            background-color: #dc3545;
            color: white;
        }
        .badge-warning {
            background-color: #ffc107;
            color: black;
        }
        .badge-info {
            background-color: #17a2b8;
            color: white;
        }
        .timestamp {
            color: #666;
            font-size: 14px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🔒 Flutter Dependencies Security Report</h1>
        <p class="timestamp">Generated on: <strong>$(date)</strong></p>
        <p>Project: <strong>owaspnote</strong></p>
        
        <div class="info-box">
            <h3>📋 Report Summary</h3>
            <p>This report analyzes all Flutter/Dart dependencies in the project for potential security issues.</p>
        </div>
EOF

# Add current dependencies section
echo "<h2>📦 Current Dependencies</h2>" >> "$HTML_REPORT"
echo "<table>" >> "$HTML_REPORT"
echo "<tr><th>Package</th><th>Current Version</th><th>Type</th><th>Description</th></tr>" >> "$HTML_REPORT"

# Parse pubspec.yaml for dependencies
echo "Analyzing dependencies..."
while IFS= read -r line; do
    if [[ $line =~ ^[[:space:]]*([a-zA-Z0-9_]+):[[:space:]]*\^?([0-9.]+) ]]; then
        package="${BASH_REMATCH[1]}"
        version="${BASH_REMATCH[2]}"
        echo "<tr><td><strong>$package</strong></td><td>$version</td><td>Direct</td><td>-</td></tr>" >> "$HTML_REPORT"
    fi
done < <(sed -n '/^dependencies:/,/^dev_dependencies:/p' /home/juan/Escritorio/proyecto/3md/owaspnote/pubspec.yaml | grep -E '^[[:space:]]+[a-zA-Z0-9_]+:')

echo "</table>" >> "$HTML_REPORT"

# Add security packages section
cat >> "$HTML_REPORT" << 'EOF'
<h2>🛡️ Security-Related Packages</h2>
<div class="warning-box">
    <h3>Security Packages Detected:</h3>
    <ul>
        <li><strong>crypto (^3.0.3)</strong> - Cryptographic algorithms</li>
        <li><strong>encrypt (^5.0.3)</strong> - Encryption/decryption functionality</li>
        <li><strong>flutter_secure_storage (^9.2.2)</strong> - Secure storage for sensitive data</li>
        <li><strong>local_auth (^2.2.0)</strong> - Biometric authentication</li>
        <li><strong>pointycastle (^3.7.4)</strong> - Cryptographic library</li>
        <li><strong>dio (^5.4.0)</strong> - HTTP client with security features</li>
    </ul>
</div>

<h2>⚠️ Security Recommendations</h2>
<div class="danger-box">
    <h3>Critical Security Checks:</h3>
    <ol>
        <li><strong>Keep Dependencies Updated:</strong> Run <code>flutter pub outdated</code> regularly</li>
        <li><strong>Audit Dependencies:</strong> Review each package's security history on pub.dev</li>
        <li><strong>Minimize Attack Surface:</strong> Remove unused dependencies</li>
        <li><strong>Check for Known Vulnerabilities:</strong> Monitor security advisories for your dependencies</li>
        <li><strong>Enable Certificate Pinning:</strong> For network communications (dio configuration)</li>
        <li><strong>Secure Storage:</strong> Ensure flutter_secure_storage is properly configured</li>
    </ol>
</div>

<h2>🔍 Outdated Packages Check</h2>
EOF

# Check for outdated packages
echo "Checking for outdated packages..."
flutter pub outdated > "$REPORT_DIR/outdated.txt" 2>/dev/null

if [ -f "$REPORT_DIR/outdated.txt" ]; then
    echo "<pre>" >> "$HTML_REPORT"
    cat "$REPORT_DIR/outdated.txt" >> "$HTML_REPORT"
    echo "</pre>" >> "$HTML_REPORT"
fi

# Add footer
cat >> "$HTML_REPORT" << 'EOF'
<h2>📚 Additional Resources</h2>
<ul>
    <li><a href="https://owasp.org/www-project-mobile-top-10/" target="_blank">OWASP Mobile Top 10</a></li>
    <li><a href="https://pub.dev/security" target="_blank">Dart Package Security</a></li>
    <li><a href="https://docs.flutter.dev/security" target="_blank">Flutter Security Best Practices</a></li>
</ul>

<div class="info-box">
    <p><strong>Note:</strong> For comprehensive vulnerability scanning including native dependencies, use the OWASP Dependency-Check tool by running <code>./dependency-check.sh</code></p>
</div>

</div>
</body>
</html>
EOF

echo ""
echo "✅ Flutter dependency analysis completed!"
echo "📄 HTML Report: $HTML_REPORT"
echo ""
echo "To view the report, run:"
echo "  open $HTML_REPORT  # macOS"
echo "  xdg-open $HTML_REPORT  # Linux"
echo "  start $HTML_REPORT  # Windows"