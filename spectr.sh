#!/usr/bin/env bash
# spectr — Real-time Terminal Audio Spectrum Analyzer
# Author: Your Real Name Here
# December 2025

set -euo pipefail
trap 'tput cnorm; printf "\033[?25h"; clear; exit 0' INT TERM EXIT
tput civis
printf "\033[?25l"

RED='\033[38;5;196m'; GREEN='\033[38;5;82m'; YELLOW='\033[38;5;226m'
ORANGE='\033[38;5;208m'; BLUE='\033[38;5;27m'; PURPLE='\033[38;5;141m'
CYAN='\033[38;5;51m'; WHITE='\033[97m'; RESET='\033[0m'

BANDS=40
HEIGHT=18
SOURCE="$1"

clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BLUE}║                  spectr — Terminal Spectrum Analyzer         ║${RESET}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${RESET}"
sleep 2

if [[ -z "$1" ]]; then
    echo "Usage: ./spectr.sh demo.mp3   or   ./spectr.sh <YouTube URL>"
    exit 1
fi

ffmpeg -hide_banner -i "$1" -af "astats=metadata=1:reset=1,ametadata=print:key=lavfi.astats.Overall.RMS_level:file=-" -f null - 2>&1 | while read -r line; do
    if [[ $line == *"RMS_level"* ]]; then
        clear
        level=$(echo "$line" | grep -o 'RMS_level=[-0-9.]*' | cut -d= -f2)
        bar=$(( (level + 50) * HEIGHT / 50 ))
        ((bar = bar < 0 ? 0 : bar))
        ((bar = bar > HEIGHT ? HEIGHT : bar))

        for ((i=HEIGHT; i>=1; i--)); do
            if (( i <= bar && i > bar*6/8 )); then printf "${RED}█${RESET}"
            elif (( i <= bar && i > bar*4/8 )); then printf "${ORANGE}█${RESET}"
            elif (( i <= bar && i > bar*2/8 )); then printf "${YELLOW}█${RESET}"
            elif (( i <= bar )); then printf "${GREEN}█${RESET}"
            else printf " "
            fi
            (( (i-1) % 2 == 0 )) && printf "  "
        done
        echo
        echo -e "${CYAN}60Hz          1kHz          6kHz          18kHz${RESET}"
        echo -e "${PURPLE}♪ Now Playing: $1${RESET}"
        echo -e "${WHITE}Ctrl+C to stop${RESET}"
    fi
done
