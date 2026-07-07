#!/usr/bin/env bash
# Build the 'keys' UI sound pack from a greeter keyboard switch.
#   hover / tick / panels / lock  -> the switch's natural (deep) key thocks
#   click                         -> the SAME switch pitched UP + lowpassed,
#                                    so clicks read higher but still muted.
# Usage: ./build_keys_pack.sh [switch] [click_pitch] [click_lp]
sw="${1:-blackink-deep}"; pitch="${2:-1.5}"; lp="${3:-2800}"
here="$(dirname "$(realpath "$0")")"
src="$here/../keyboard/$sw"; dst="$here/keys"
[ -d "$src" ] || { echo "no switch '$sw' at $src"; exit 1; }
rm -rf "$dst"; mkdir -p "$dst"
cp "$src/r0.wav" "$dst/hover_0.wav"; cp "$src/r1.wav" "$dst/hover_1.wav"; cp "$src/r2.wav" "$dst/hover_2.wav"; cp "$src/r3.wav" "$dst/hover_3.wav"
cp "$src/r0.wav" "$dst/tick_0.wav"; cp "$src/r2.wav" "$dst/tick_1.wav"; cp "$src/r4.wav" "$dst/tick_2.wav"
cp "$src/enter.wav" "$dst/toggle-on.wav"; cp "$src/r4.wav" "$dst/toggle-off.wav"
cp "$src/space.wav" "$dst/panel-open.wav"; cp "$src/enter.wav" "$dst/panel-close.wav"
cp "$src/space.wav" "$dst/lock.wav"; cp "$src/enter.wav" "$dst/unlock.wav"
cp "$src/space.wav" "$dst/screenshot.wav"
cp "$src/enter.wav" "$dst/charge-plug.wav"; cp "$src/r0.wav" "$dst/charge-unplug.wav"
cp "$src/r4.wav" "$dst/error.wav"
i=0
for r in r1 r2 r3; do
  ffmpeg -y -loglevel error -i "$src/$r.wav" -af "asetrate=48000*${pitch},aresample=48000,lowpass=f=${lp},volume=0.9" -ar 48000 -ac 1 -acodec pcm_s16le "$dst/click_${i}.wav"
  i=$((i+1))
done
echo "built keys pack from '$sw' (click pitch=${pitch}, lp=${lp}Hz)"
