# spectr — Real-time Terminal Audio Spectrum Analyzer 🎵

A real-time audio visualizer that works on MP3 files and YouTube links. Written **entirely in Bash**.

No Python. No ncurses. Just `ffmpeg`, `bash`, and pure terminal magic.

## Problem I Solved
I wanted to show off hardcore Bash skills with something visual and fun that runs anywhere (even servers with no GUI).

## Features
- 40 frequency bands with falling peaks
- Smooth color transitions (green → yellow → red)
- Supports local files and YouTube URLs
- Works perfectly in GitHub CodeSpaces
- Zero heavy dependencies

## How to run (works in GitHub CodeSpaces!)

```bash
chmod +x install-deps.sh spectr.sh
./install-deps.sh  # Installs/updates ffmpeg + yt-dlp
./spectr.sh demo.mp3  # Should show pulsing bars immediately

# Or paste any YouTube link:

./spectr.sh https://www.youtube.com/watch?v=y6120QOlsfU   # Darude - Sandstorm
```

## Attribution & Thanks
Built with help from Grok (xAI) • Inspired by classic terminal demos

## License
MIT © 2025 Tina Bowles
