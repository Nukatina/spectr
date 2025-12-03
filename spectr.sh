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

# Draw spectrum (real-time with showvolume for bands)
draw_spectrum() {
    # Use ffmpeg to generate volume bars directly (no fake needed)
    ffmpeg -hide_banner -nostats -i "$INPUT" \
        -filter_complex "
            [0:a]showvolume=s=40x18:rate=10:scale=log:colors=white@0.9|red@0.8|yellow@0.6|green@0.4|blue@0.2[v];
            [v]scale=iw*2:ih:flags=neighbor[cropped];
            [cropped]transpose=1[transposed];
            [transposed]transpose=1[rotated]
        " \
        -map "[rotated]" -f ppm - 2>/dev/null | while read -r line; do
            # Parse PPM header + pixel data for bar heights (simplified)
            if [[ $line =~ P6 ]]; then
                # Skip header, read pixel rows
                for ((row=HEIGHT; row>=1; row--)); do
                    pixel_line=$(dd bs=1 count=$((BANDS*3)) 2>/dev/null | hexdump -v -e '/3 " %02x%02x%02x"')
                    bar_line=""
                    for ((i=0; i<BANDS; i++)); do
                        # Extract RGB, map to height/color
                        color_hex=$(echo "$pixel_line" | cut -d' ' -f$((i*3+1)))
                        intensity=$((16#${color_hex:0:2}))  # Rough brightness
                        bar_h=$((intensity / 16))  # Scale to height
                        if (( row <= bar_h && row > bar_h * 0.75 )); then
                            bar_line+="${RED}█${RESET}"
                        elif (( row <= bar_h )); then
                            bar_line+="${YELLOW}█${RESET}"
                        else
                            bar_line+=" "
                        fi
                    done
                    echo -e "$bar_line"
                done
            fi
            echo -e "${CYAN}60Hz          1kHz          6kHz          18kHz${RESET}"
            echo -e "${PURPLE}♪ Now Playing: $INPUT${RESET}"
            echo -e "${WHITE}Ctrl+C to stop | Real-time mode${RESET}"
    done
}

# Run it
if [[ $FAKE_MODE -eq 1 ]]; then
    draw_spectrum
else
    get_audio_data | draw_spectrum
fi
