#!/bin/bash

echo "🔧 Fixing iOS build issues..."

# Remove extended attributes from all build files
echo "Removing extended attributes..."
find /Users/victoromorogbe/Documents/pally -name "*.framework" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.dylib" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.a" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.app" -exec xattr -cr {} \; 2>/dev/null || true

# Remove extended attributes from Flutter framework specifically
echo "Fixing Flutter framework extended attributes..."
find /Users/victoromorogbe/Documents/pally/build -name "Flutter.framework" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally/build -name "Flutter.framework" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

# Clean Flutter
echo "Cleaning Flutter..."
cd /Users/victoromorogbe/Documents/pally
flutter clean

# Clean iOS build completely
echo "Cleaning iOS build..."
rm -rf build/ios
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/.symlinks
rm -rf ios/Flutter/Generated.xcconfig
rm -rf ios/Flutter/flutter_export_environment.sh
rm -rf ios/Flutter/Flutter.podspec

# Get Flutter dependencies first
echo "Getting Flutter dependencies..."
flutter pub get

# Generate Flutter files
echo "Generating Flutter files..."
flutter packages get

# Clean and reinstall pods
echo "Reinstalling pods..."
cd ios
pod deintegrate 2>/dev/null || true
pod install --repo-update

# Fix xcconfig files
echo "Fixing xcconfig files..."
cd /Users/victoromorogbe/Documents/pally
flutter packages get

# Ensure Generated.xcconfig exists
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "Creating Generated.xcconfig..."
    mkdir -p ios/Flutter
    echo "FLUTTER_ROOT=/opt/homebrew/bin/flutter" > ios/Flutter/Generated.xcconfig
    echo "FLUTTER_APPLICATION_PATH=/Users/victoromorogbe/Documents/pally" >> ios/Flutter/Generated.xcconfig
    echo "COCOAPODS_PARALLEL_CODE_SIGN=true" >> ios/Flutter/Generated.xcconfig
    echo "FLUTTER_TARGET=lib/main.dart" >> ios/Flutter/Generated.xcconfig
    echo "FLUTTER_BUILD_DIR=build" >> ios/Flutter/Generated.xcconfig
    echo "FLUTTER_BUILD_NAME=1.0.0" >> ios/Flutter/Generated.xcconfig
    echo "FLUTTER_BUILD_NUMBER=1" >> ios/Flutter/Generated.xcconfig
    echo "EXCLUDED_ARCHS[sdk=iphonesimulator*]=arm64" >> ios/Flutter/Generated.xcconfig
    echo "DART_OBFUSCATION=false" >> ios/Flutter/Generated.xcconfig
    echo "TRACK_WIDGET_CREATION=true" >> ios/Flutter/Generated.xcconfig
    echo "TREE_SHAKE_ICONS=false" >> ios/Flutter/Generated.xcconfig
    echo "PACKAGE_CONFIG=.dart_tool/package_config.json" >> ios/Flutter/Generated.xcconfig
fi

# Fix Pods-Runner xcfilelist issues
echo "Fixing xcfilelist issues..."
cd ios
if [ -d "Pods/Target Support Files/Pods-Runner" ]; then
    # Create missing xcfilelist files
    touch "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Debug-input-files.xcfilelist"
    touch "Pods/Target Support Files/Pods-Runner/Pods-Runner-frameworks-Debug-output-files.xcfilelist"
    touch "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Debug-input-files.xcfilelist"
    touch "Pods/Target Support Files/Pods-Runner/Pods-Runner-resources-Debug-output-files.xcfilelist"
fi

# Final extended attributes cleanup
echo "Final cleanup of extended attributes..."
find /Users/victoromorogbe/Documents/pally -name "*.framework" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.dylib" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.a" -exec xattr -cr {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.app" -exec xattr -cr {} \; 2>/dev/null || true

# Remove quarantine attributes
find /Users/victoromorogbe/Documents/pally -name "*.framework" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.dylib" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true
find /Users/victoromorogbe/Documents/pally -name "*.a" -exec xattr -d com.apple.quarantine {} \; 2>/dev/null || true

echo "✅ iOS build fixes applied!"
echo "Now try: flutter run -d '00008030-000554943ED1802E'"
