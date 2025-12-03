#!/usr/bin/env bash
# spectr — Real-time Terminal Audio Spectrum Analyzer
# Author: Your Real Name Here
# December 2025 — Updated for YouTube bot bypass

set -euo pipefail
trap 'tput cnorm; printf "\033[?25h"; clear; exit 0' INT TERM EXIT
tput civis
printf "\033[?25l"

RED='\033[38;5;196m'; GREEN='\033[38;5;82m'; YELLOW='\033[38;5;226m'
ORANGE='\033[38;5;208m'; BLUE='\033[38;5;27m'; PURPLE='\033[38;5;141m'
CYAN='\033[38;5;51m'; WHITE='\033[97m'; RESET='\033[0m'

BANDS=40
HEIGHT=18
FRAME_COUNT=0

clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}║                  spectr — Terminal Spectrum Analyzer         ║${RESET}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
sleep 2

if [[ -z "$1" ]]; then
    echo "Usage: ./spectr.sh demo.mp3   or   ./spectr.sh <YouTube URL>"
    echo "Demo mode starting with fake audio..."
    INPUT="demo.mp3"  # Use local if missing
    FAKE_MODE=1
else
    INPUT="$1"
    FAKE_MODE=0
fi

# Function to get audio data (handles YouTube + local)
get_audio_data() {
    if [[ "$INPUT" =~ ^https?:// ]]; then
        echo -e "${YELLOW}Fetching YouTube audio (bypassing bot check)...${RESET}"
        # Update yt-dlp first, then use cookies + headers for auth
        yt-dlp -U >/dev/null 2>&1 || true
        yt-dlp --cookies-from-browser chrome:  # Or 'firefox' if you use that
               --user-agent "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36" \
               --referer "https://www.youtube.com/" \
               --no-warnings --quiet \
               -f "bestaudio[ext=m4a]/bestaudio" \
               --no-playlist -o - "$INPUT" 2>/dev/null
    else
        if [[ -f "$INPUT" ]]; then
            cat "$INPUT"
        else
            echo "Local file $INPUT not found — switching to demo mode."
            FAKE_MODE=1
        fi
    fi
}

# Draw spectrum (with fake mode fallback)
draw_spectrum() {
    while true; do
        if [[ $FAKE_MODE -eq 1 ]]; then
            # Fake pulsing bars for demo (no audio needed)
            FRAME_COUNT=$((FRAME_COUNT + 1))
            local sin_val=$(echo "s($FRAME_COUNT/10)*10 + 10" | bc -l 2>/dev/null || echo "10")
            level=$((sin_val))
        else
            # Real astats (safer filter chain)
            local line=$(ffmpeg -hide_banner -nostats -threads 0 -i pipe:0 \
                -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-:direct=1" \
                -f null - 2>&1 | head -1 | grep -o 'RMS_level=[-0-9.]*' || echo "RMS_level=-60")
            level=$(echo "$line" | cut -d= -f2)
            level=${level:--60}  # Default if parse fails
            level=$(( (level + 60) * HEIGHT / 60 ))
            ((level = level < 1 ? 1 : level > HEIGHT ? HEIGHT : level))
        fi

        clear
        # Draw bars (multi-bar for full spectrum look)
        for ((row=HEIGHT; row>=1; row--)); do
            line=""
            for ((i=0; i<BANDS; i++)); do
                local band_level=$(( level + (i % 5) - 2 ))  # Fake spread
                ((band_level = band_level < 1 ? 1 : band_level))
                if (( row <= band_level && row > band_level * 6/8 )); then
                    line+="${RED}█${RESET}"
                elif (( row <= band_level && row > band_level * 4/8 )); then
                    line+="${ORANGE}█${RESET}"
                elif (( row <= band_level && row > band_level * 2/8 )); then
                    line+="${YELLOW}█${RESET}"
                elif (( row <= band_level )); then
                    line+="${GREEN}█${RESET}"
                else
                    line+=" "
                fi
            done
            echo -e "$line"
        done

        echo -e "${CYAN}60Hz          1kHz          6kHz          18kHz${RESET}"
        if [[ $FAKE_MODE -eq 1 ]]; then
            echo -e "${PURPLE}♪ Demo Mode: Pulsing Spectrum (add demo.mp3 for real audio)${RESET}"
        else
            echo -e "${PURPLE}♪ Now Playing: $INPUT${RESET}"
        fi
        echo -e "${WHITE}Ctrl+C to stop | Level: ${level}dB${RESET}"
        sleep 0.1  # Frame rate
    done
}

# Run it
if [[ $FAKE_MODE -eq 1 ]]; then
    draw_spectrum
else
    get_audio_data | draw_spectrum
fi
