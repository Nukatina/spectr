#!/usr/bin/env bash
echo "Installing everything (this takes ~30 seconds)..."
sudo apt update -qq && sudo apt install -y ffmpeg yt-dlp pulseaudio > /dev/null 2>&1
echo "✅ All done! Now run: ./spectr.sh demo.mp3"
