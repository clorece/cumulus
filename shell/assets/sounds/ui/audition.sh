#!/usr/bin/env bash
# Audition a UI sound pack — plays every cue in it with its name.
# Usage: ./audition.sh [pack]   (default: thock)
pack="${1:-thock}"
dir="$(dirname "$(realpath "$0")")/$pack"
[ -d "$dir" ] || { echo "no pack '$pack' at $dir"; exit 1; }
echo "Auditioning '$pack' from $dir"
for f in "$dir"/*.wav; do
  printf "  ▶ %-18s\n" "$(basename "$f" .wav)"
  paplay "$f" 2>/dev/null
  sleep 0.4
done
echo "done."
