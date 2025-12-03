#!/usr/bin/env bash
echo "Installing dependencies for GitHub CodeSpaces..."
sudo apt update && sudo apt install -y ffmpeg yt-dlp pulseaudio
echo "All set! Run: ./spectr.sh demo.mp3"
