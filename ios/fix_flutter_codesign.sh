#!/bin/bash

# Fix Flutter framework codesigning issues
echo "🔧 Fixing Flutter framework codesigning issues..."

# Find and fix Flutter framework
find /Users/victoromorogbe/Documents/pally/build -name "Flutter.framework" -type d | while read framework; do
    echo "Processing: $framework"
    
    # Remove all extended attributes
    xattr -cr "$framework" 2>/dev/null || true
    
    # Remove quarantine attributes
    xattr -d com.apple.quarantine "$framework" 2>/dev/null || true
    
    # Remove any existing code signature
    codesign --remove-signature "$framework/Flutter" 2>/dev/null || true
    
    # Remove the _CodeSignature directory if it exists
    rm -rf "$framework/_CodeSignature" 2>/dev/null || true
    
    # Re-sign with ad-hoc signature
    codesign --force --sign - "$framework/Flutter" 2>/dev/null || true
done

echo "✅ Flutter framework codesigning fixes applied!"
