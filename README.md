# spectr — Real-time Terminal Audio Spectrum Analyzer

**A stunning 40-band real-time audio spectrum visualizer written entirely in Bash.**

No Python. No ncurses. Just `ffmpeg`, `bash`, and pure terminal magic.

## Features
- 40 frequency bands with falling peaks
- Smooth color transitions (green → yellow → red)
- Supports local files and YouTube URLs
- Works perfectly in GitHub CodeSpaces
- Zero heavy dependencies

## Live Demo
```bash
./spectr.sh demo.mp3

# Or try:

./spectr.sh https://www.youtube.com/watch?v=y6120QOlsfU   # Darude - Sandstorm
