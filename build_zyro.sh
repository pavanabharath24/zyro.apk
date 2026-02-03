#!/bin/bash
set -e

echo "🚀 Starting optimized build for Zyro..."

# Run the release build
flutter build apk --release

# Define paths
SOURCE_APK="build/app/outputs/flutter-apk/app-release.apk"
DEST_APK="zyro.apk"

# Check if build was successful
if [ -f "$SOURCE_APK" ]; then
    echo "✅ Build successful!"
    
    # Rename/Copy to zyro.apk
    cp "$SOURCE_APK" "$DEST_APK"
    
    echo "📦 Copied to $DEST_APK"
    
    # Print size
    SIZE=$(ls -lh "$DEST_APK" | awk '{print $5}')
    echo "📊 New App Size: $SIZE"
    
    echo "🎉 Ready to share! File: $(pwd)/$DEST_APK"
else
    echo "❌ Build failed! APK not found."
    exit 1
fi
