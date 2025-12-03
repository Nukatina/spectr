#!/usr/bin/env bash
# =============================================================================
# spectr — Stunning Real-time Audio Spectrum Analyzer in Pure Bash
# Author: Nukatina
# GitHub: https://github.com/Nukatina/spectr
# License: MIT
# =============================================================================

set -euo pipefail
trap 'tput cnorm; stty echo; printf "\033[?25h"; clear; exit 0' INT TERM EXIT

# Hide cursor & setup colors
tput civis
printf "\033[?25l"

RED='\033[38;5;196m'; GREEN='\033[38;5;82m'; YELLOW='\033[38;5;226m'
ORANGE='\033[38;5;208m'; BLUE='\033[38;5;27m'; PURPLE='\033[38;5;141m'
CYAN='\033[38;5;51m'; WHITE='\033[97m'; RESET='\033[0m'

BANDS=40
HEIGHT=18
WIDTH=$(tput cols)
FIFO=$(mktemp -u /tmp/spectr.XXXXXX)
mkfifo "$FIFO"

# Falling peak state
declare -a peaks
for ((i=0; i<BANDS; i++)); do peaks[i]=0; done

# Frequency labels (log scale)
labels=("60" "100" "200" "400" "800" "1.6k" "3.2k" "6.4k" "12k" "18k")
label_positions=()

draw_bars() {
    local frame="$1"
    clear

    # Parse magnitudes from ffmpeg astats
    local vals=($(echo "$frame" | grep -o 'lavfi.astats.[0-9]*.RMS_level=[-0-9.]*' | cut -d= -f2 | head -10))
    local band_width=$((WIDTH / BANDS))
    local now=$(date +%H:%M:%S)

    # Draw bars row by row (top to bottom)
    for ((row=HEIGHT; row>=1; row--)); do
        line=""
        for ((i=0; i<BANDS; i++)); do
            # Simulate logarithmic frequency distribution
            local log_i=$((i * 10 / BANDS))
            local level_dB=${vals[$log_i]:--90}
            local level=$(( (level_dB + 60) * HEIGHT / 60 ))
            ((level = level < 0 ? 0 : level))
            ((level = level > HEIGHT ? HEIGHT : level))

            if (( row <= level && row > level * 4/5 )); then
                line+="${RED}█${RESET}"
            elif (( row <= level && row > level * 3/5 )); then
                line+="${ORANGE}█${RESET}"
            elif (( row <= level && row > level * 2/5 )); then
                line+="${YELLOW}█${RESET}"
            elif (( row <= level )); then
                line+="${GREEN}█${RESET}"
            elif (( row <= peaks[i] )); then
                line+="${CYAN}•${RESET}"
            else
                line+=" "
            fi

            # Update falling peaks
            (( level > peaks[i] )) && peaks[i]=$level
            (( peaks[i] > 0 )) && ((peaks[i]--))
        done
        echo -e "$line"
    done

    # Bottom labels
    label_line=" "
    for ((i=0; i<${#labels[@]}; i++)); do
        pos=$(( (i + 0.5) * WIDTH / ${#labels[@]} - ${#labels[i]}/2 ))
        printf "%*s%s" $pos "" "${CYAN}${labels[i]}${RESET}"
    done
    echo

    echo -e "${PURPLE}♪ Now Playing: ${WHITE}$(basename "$SOURCE")${RESET}   ${BLUE}[$now]${RESET}"
    echo -e "${WHITE}Press Ctrl+C to exit${RESET}"
}

# Main visualization loop
visualize() {
    local source="$1"
    SOURCE="$source"

    ffmpeg -hide_banner -nostats -i "$source" \
        -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.1.RMS_level:file=-:line=0" \
        -f null - 2>&1 | while IFS= read -r line; do
            if [[ $line == *"lavfi.astats"* ]]; then
                draw_bars "$line"
            fi
        done
}

# Start playback and visualization
play_and_visualize() {
    local input="$1"

    if [[ $input =~ ^https?:// ]]; then
        echo -e "${YELLOW}Downloading audio stream... (yt-dlp)${RESET}"
        yt-dlp -q --no-playlist -f 'bestaudio' -o - "$input" | \
            ffmpeg -re -i pipe:0 -f pulse "spectr" -vn -af "volume=1.5" >/dev/null 2>&1 &
        visualize "pipe:0" <(yt-dlp -q --no-playlist -f 'bestaudio' -o - "$input")
    else
        ffmpeg -re -i "$input" -f pulse "spectr" -vn -af "volume=1.5" >/dev/null 2>&1 &
        visualize "$input"
    fi
}

# === Main ===
clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}║                  spectr — Terminal Spectrum Analyzer         ║${RESET}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
sleep 2

if [[ -z "${1:-}" ]]; then
    echo -e "${YELLOW}Usage:${RESET} ./spectr.sh <file.mp3> ${CYAN}or${RESET} ./spectr.sh <YouTube URL>"
    echo -e "${GREEN}Demo:${RESET} ./spectr.sh demo.mp3"
    exit 1
fi

play_and_visualize "$1"
