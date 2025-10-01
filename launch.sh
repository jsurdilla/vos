#!/bin/bash

# VoiceOS Launch Script

echo "🎤 VoiceOS - Audio Transcription App"
echo ""

# Build if needed
if [ ! -f "./.build/debug/VoiceOS" ]; then
    echo "Building VoiceOS..."
    swift build
    echo ""
fi

# Check for required permissions
echo "📋 Pre-flight checks:"
echo "  ✓ Make sure to grant Microphone permission when prompted"
echo "  ✓ For global shortcuts, grant Accessibility permission if needed"
echo ""

echo "🚀 Launching VoiceOS..."
echo "  • Click the microphone icon in menu bar to start/stop recording"
echo "  • Or use Cmd+Shift+R keyboard shortcut"
echo ""

# Launch the app
./.build/debug/VoiceOS
