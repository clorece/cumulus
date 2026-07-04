#!/usr/bin/env python3
"""
Generate Caelestia colour schemes for the Cumulus skin, one per wallpaper preset.

Each preset is authored as (flavour, wall, mode, bg, accent, accent2), picked
from the wallpaper's dominant clusters + a visual pass:
  - mode  matches the wallpaper's lighting: bright airy walls get true light
          schemes, night scenes stay dark (but hue-rich, not near-black)
  - bg    carries the wallpaper's ambient hue at a readable lightness
  - accent   = the wallpaper's pop colour, tuned to read on the cards
  - accent2  = a supporting hue from the image (complement/triad where the
               composition has one)
cardLight / cardDark / accentInk are derived per mode.

Outputs, per preset <flavour>:
  schemes/cumulus/<flavour>/<mode>.txt -> installable via `caelestia scheme set`
  state/<flavour>.json               -> drop-in ~/.local/state/caelestia/scheme.json
  state/wallmap.json                 -> flavour -> wallpaper map for the cycle script

Run:  python3 generate_schemes.py
"""
import colorsys
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = os.path.join(HERE, "..", "active-scheme.json")

PRESETS = [
    # flavour           wall    mode     bg        accent    accent2
    ("sunset-pitstop",     "nw1",  "dark",  "1d1727", "eca89d", "96a8d9"),  # dusk-pink glow / periwinkle shadow
    ("seaside-respite",  "nw2",  "dark",  "102028", "66b8dc", "dcb08a"),  # moonlit sea / warm skin+sand
    ("solace",   "nw3",  "dark",  "251511", "e0725a", "e3bd92"),  # warm red floor / cream paper
    ("elation",     "nw4",  "dark",  "1a1426", "e29468", "ab8fe0"),  # butterfly orange vs violet dusk
    ("pastel-dreams",  "nw5",  "light", "e6ddf0", "c26b96", "7d88c4"),  # pastel lavender, pink prominent
    ("research-study",   "nw6",  "dark",  "1b1b12", "e8cda6", "8fb897"),  # lamp glow / plant green
    ("fleeting-moments",    "nw7",  "dark",  "13221e", "6cc9b4", "dca26e"),  # aqua canopy / amber jacket
    ("expeditions",     "nw8",  "dark",  "151c30", "8fb3e6", "e0e2b2"),  # sail blue / pale chartreuse
    ("yearning",  "nw9",  "dark",  "1c1424", "eccc8a", "bd98b9"),  # luminous gold vs plum cabin
    ("journey",       "nw10", "dark",  "132019", "85c9b7", "b8cfd8"),  # storm teal / pale sky
    ("reflection",      "nw11", "light", "dfe3e8", "5580a8", "b3766a"),  # silver overcast / steel + clay
    ("dusk-harbor",     "nw12", "dark",  "182523", "e2ad7a", "72bcc2"),  # dock lights vs teal water
    ("aspirations",     "nw13", "dark",  "0e181c", "e28749", "60a8bd"),  # ember vs deep night teal
    ("vinyl-halo",      "nw14", "light", "dad4c9", "a8853f", "5c7a9e"),  # greige plaza, gold halo / shark blue
    ("seaside-stroll",      "nw15", "light", "e5d6d0", "b06b60", "caa38f"),  # rosy daylight, analogous clays
    ("obscuram",     "nw16", "dark",  "15172b", "9aa6e3", "e2a76a"),  # indigo night / campfire
    ("lingering-moments", "nw17", "dark",  "0f1c29", "82b6dc", "c1bcdf"),  # lamp blue / pale lavender
    ("island-three",    "nw18", "dark",  "13242c", "66cca8", "dcd285"),  # neon green / signage yellow
    ("wondering-beyond",         "nw19", "light", "dcebd6", "4e8f57", "b0806f"),  # fresh leaf light / warm blush
    ("flaura", "nw20", "dark",  "0d201f", "4fd1b8", "e2a97e"),  # verdigris / sunset peach
    ("solitude",       "nw21", "light", "def0ec", "3d8f86", "9a9556"),  # pale aqua sky / olive-gold cloud
    ("olive-marina",    "nw22", "light", "e8e0c4", "8f7d35", "5c7186"),  # butter cream / slate water
    ("post-anthropocene",     "nw23", "dark",  "182212", "e2c964", "97b56e"),  # sign yellow / moss
    ("ponder",      "nw24", "light", "e3dac9", "b04a44", "6f8a5c"),  # sand light, scarf red / leaf green
]

# ---------- colour math ----------
def to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i+2], 16) for i in (0, 2, 4))

def to_hex(rgb):
    return "".join(f"{max(0,min(255,round(c))):02x}" for c in rgb)

def mix(a, b, t):
    """t fraction of b blended into a."""
    ra, rb = to_rgb(a), to_rgb(b)
    return to_hex(tuple(ra[i] * (1 - t) + rb[i] * t for i in range(3)))

def lighten(c, t): return mix(c, "ffffff", t)
def darken(c, t):  return mix(c, "000000", t)

def lum(c):
    r, g, b = (x / 255 for x in to_rgb(c))
    return (0.299 * r ** 2 + 0.587 * g ** 2 + 0.114 * b ** 2) ** 0.5

def on(c):
    """Readable ink for a filled surface of colour c."""
    return darken(c, 0.80) if lum(c) > 0.5 else lighten(c, 0.82)

def hls(c):
    r, g, b = (x / 255 for x in to_rgb(c))
    return colorsys.rgb_to_hls(r, g, b)

def set_hls(c, l=None, max_s=None):
    """Re-light a colour keeping its hue (optionally capping saturation)."""
    h, l0, s = hls(c)
    if l is not None: l0 = l
    if max_s is not None: s = min(s, max_s)
    return to_hex(tuple(x * 255 for x in colorsys.hls_to_rgb(h, l0, s)))

def rel_lum(c):
    def chan(x):
        x /= 255
        return x / 12.92 if x <= 0.04045 else ((x + 0.055) / 1.055) ** 2.4
    r, g, b = to_rgb(c)
    return 0.2126 * chan(r) + 0.7152 * chan(g) + 0.0722 * chan(b)

def contrast(a, b):
    la, lb = sorted((rel_lum(a), rel_lum(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)

def ensure_contrast(c, against, target):
    """Deepen c along its own hue until it reads against `against`. Keeps the
    authored hue/saturation — pastel surfaces stay pastel, only the accent
    ink-weight changes."""
    h, l, s = hls(c)
    while contrast(c, against) < target and l > 0.12:
        l -= 0.02
        c = to_hex(tuple(x * 255 for x in colorsys.hls_to_rgb(h, l, s)))
    return c

def derive(mode, bg, accent, accent2):
    """Expand an authored triple to the full palette dict. Cards sit relative
    to the bg lightness so hue-rich raised bases keep their chroma."""
    l_bg = hls(bg)[1]
    if mode == "light":
        card_dark = set_hls(bg, l=l_bg - 0.07)
        accent = ensure_contrast(accent, card_dark, 3.8)
        accent2 = ensure_contrast(accent2, card_dark, 3.2)
        return dict(
            bg=bg,
            cardLight=set_hls(bg, l=min(l_bg + 0.06, 0.94)),
            cardDark=card_dark,
            accent=accent,
            accentInk=on(accent),
            accent2=accent2,
        )
    return dict(
        bg=bg,
        cardLight=set_hls(bg, l=l_bg + 0.10, max_s=0.38),
        cardDark=set_hls(bg, l=l_bg + 0.04, max_s=0.38),
        accent=accent,
        accentInk=set_hls(accent, l=0.13),
        accent2=accent2,
    )


def build_dark(p):
    bg, cl, cd = p["bg"], p["cardLight"], p["cardDark"]
    accent, ink, accent2 = p["accent"], p["accentInk"], p["accent2"]
    white = mix("ffffff", accent, 0.06)          # faintly accent-tinted text white
    secondary = lighten(mix(accent2, accent, 0.35), 0.12)

    return {
        "primary_paletteKeyColor": accent,
        "secondary_paletteKeyColor": mix(accent2, accent, 0.4),
        "tertiary_paletteKeyColor": accent2,
        "neutral_paletteKeyColor": mix(cl, "808080", 0.5),
        "neutral_variant_paletteKeyColor": mix(cl, "808080", 0.5),
        "background": bg,
        "onBackground": white,
        "surface": bg,
        "surfaceDim": bg,
        "surfaceBright": lighten(cl, 0.12),
        "surfaceContainerLowest": darken(bg, 0.35),
        "surfaceContainerLow": mix(bg, cd, 0.55),
        "surfaceContainer": cd,
        "surfaceContainerHigh": mix(cd, cl, 0.55),
        "surfaceContainerHighest": cl,
        "onSurface": white,
        "surfaceVariant": lighten(cl, 0.05),
        "onSurfaceVariant": mix("c4c6d0", accent, 0.10),
        "inverseSurface": white,
        "inverseOnSurface": cd,
        "outline": mix("8e909a", accent, 0.12),
        "outlineVariant": mix(cl, accent, 0.06),
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": accent,
        "primary": accent,
        "onPrimary": ink,
        "primaryContainer": darken(accent, 0.18),
        "onPrimaryContainer": lighten(accent, 0.75),
        "inversePrimary": darken(accent, 0.35),
        "secondary": secondary,
        "onSecondary": on(secondary),
        "secondaryContainer": mix(cl, accent, 0.12),
        "onSecondaryContainer": lighten(accent2, 0.70),
        "tertiary": accent2,
        "onTertiary": on(accent2),
        "tertiaryContainer": darken(accent2, 0.18),
        "onTertiaryContainer": on(darken(accent2, 0.18)),
        "error": "ffb4ab", "onError": "690005",
        "errorContainer": "93000a", "onErrorContainer": "ffdad6",
        "success": "b5ccba", "onSuccess": "213528",
        "successContainer": "374b3e", "onSuccessContainer": "d1e9d6",
        "primaryFixed": lighten(accent, 0.75), "primaryFixedDim": accent,
        "onPrimaryFixed": darken(accent, 0.70), "onPrimaryFixedVariant": darken(accent, 0.20),
        "secondaryFixed": lighten(secondary, 0.55), "secondaryFixedDim": secondary,
        "onSecondaryFixed": on(secondary), "onSecondaryFixedVariant": darken(secondary, 0.40),
        "tertiaryFixed": lighten(accent2, 0.70), "tertiaryFixedDim": accent2,
        "onTertiaryFixed": darken(accent2, 0.70), "onTertiaryFixedVariant": darken(accent2, 0.40),
        # terminal
        "term0": mix(cd, cl, 0.55), "term8": mix("8e909a", accent, 0.12),
        "term1": accent, "term9": lighten(accent, 0.15),
        "term2": accent2, "term10": lighten(accent2, 0.15),
        "term3": mix(accent, "ffffff", 0.35), "term11": lighten(mix(accent, "ffffff", 0.35), 0.20),
        "term4": mix(accent2, accent, 0.5), "term12": lighten(mix(accent2, accent, 0.5), 0.15),
        "term5": lighten(accent, 0.35), "term13": lighten(accent, 0.50),
        "term6": mix(accent2, "ffffff", 0.30), "term14": lighten(mix(accent2, "ffffff", 0.30), 0.10),
        "term7": white, "term15": "ffffff",
        # catppuccin-ish extras (external app templates)
        "rosewater": lighten(accent, 0.55), "flamingo": lighten(accent, 0.45),
        "pink": mix(accent, "ffffff", 0.40), "mauve": mix(accent, accent2, 0.5),
        "red": accent, "maroon": darken(accent, 0.10), "peach": accent2,
        "yellow": mix(accent2, "ffffff", 0.25), "green": "b5ccba",
        "teal": mix(accent2, accent, 0.30), "sky": mix(accent2, "ffffff", 0.30),
        "sapphire": mix(accent, accent2, 0.40), "blue": mix(accent, "ffffff", 0.20),
        "lavender": lighten(mix(accent, accent2, 0.5), 0.20),
        "klink": accent, "klinkSelection": accent,
        "kvisited": darken(accent, 0.15), "kvisitedSelection": darken(accent, 0.15),
        "knegative": "ff6b6b", "knegativeSelection": "ff6b6b",
        "kneutral": accent2, "kneutralSelection": accent2,
        "kpositive": mix(accent2, "00ffaa", 0.35), "kpositiveSelection": mix(accent2, "00ffaa", 0.35),
        "text": white, "subtext1": mix("c4c6d0", accent, 0.10), "subtext0": mix("8e909a", accent, 0.12),
        "overlay2": mix(mix("8e909a", accent, 0.12), cl, 0.30),
        "overlay1": mix(mix("8e909a", accent, 0.12), cl, 0.50),
        "overlay0": mix(mix("8e909a", accent, 0.12), cl, 0.70),
        "surface2": mix(cd, cl, 0.55), "surface1": cd, "surface0": mix(bg, cd, 0.55),
        "base": bg, "mantle": darken(bg, 0.15), "crust": darken(bg, 0.30),
    }


def build_light(p):
    """Light-mode mapping: elevated stays lighter (matches the top-lit matte
    look), text is a dark accent-tinted ink, accents are authored deep enough
    to read on the pale cards."""
    bg, cl, cd = p["bg"], p["cardLight"], p["cardDark"]
    accent, ink, accent2 = p["accent"], p["accentInk"], p["accent2"]
    text = mix(set_hls(bg, l=0.14), accent, 0.08)
    secondary = darken(mix(accent2, accent, 0.35), 0.08)
    grey = set_hls(bg, l=0.42)                    # bg-tinted mid grey

    return {
        "primary_paletteKeyColor": accent,
        "secondary_paletteKeyColor": mix(accent2, accent, 0.4),
        "tertiary_paletteKeyColor": accent2,
        "neutral_paletteKeyColor": mix(cd, "808080", 0.5),
        "neutral_variant_paletteKeyColor": mix(cd, "808080", 0.5),
        "background": bg,
        "onBackground": text,
        "surface": bg,
        "surfaceDim": darken(bg, 0.06),
        "surfaceBright": lighten(bg, 0.10),
        "surfaceContainerLowest": lighten(bg, 0.55),
        "surfaceContainerLow": mix(bg, cl, 0.55),
        "surfaceContainer": cd,
        "surfaceContainerHigh": mix(cd, cl, 0.45),
        "surfaceContainerHighest": cl,
        "onSurface": text,
        "surfaceVariant": darken(bg, 0.05),
        "onSurfaceVariant": mix(set_hls(bg, l=0.32), accent, 0.10),
        "inverseSurface": text,
        "inverseOnSurface": cl,
        "outline": mix("74767f", accent, 0.12),
        "outlineVariant": mix(cd, accent, 0.06),
        "shadow": "000000",
        "scrim": "000000",
        "surfaceTint": accent,
        "primary": accent,
        "onPrimary": ink,
        "primaryContainer": lighten(accent, 0.62),
        "onPrimaryContainer": darken(accent, 0.45),
        "inversePrimary": lighten(accent, 0.40),
        "secondary": secondary,
        "onSecondary": on(secondary),
        "secondaryContainer": mix(cl, accent, 0.14),
        "onSecondaryContainer": darken(accent2, 0.45),
        "tertiary": accent2,
        "onTertiary": on(accent2),
        "tertiaryContainer": lighten(accent2, 0.55),
        "onTertiaryContainer": darken(accent2, 0.50),
        "error": "ba1a1a", "onError": "ffffff",
        "errorContainer": "ffdad6", "onErrorContainer": "410002",
        "success": "38693c", "onSuccess": "ffffff",
        "successContainer": "b9f0b8", "onSuccessContainer": "002105",
        "primaryFixed": lighten(accent, 0.62), "primaryFixedDim": accent,
        "onPrimaryFixed": darken(accent, 0.55), "onPrimaryFixedVariant": darken(accent, 0.25),
        "secondaryFixed": lighten(secondary, 0.55), "secondaryFixedDim": secondary,
        "onSecondaryFixed": darken(secondary, 0.45), "onSecondaryFixedVariant": darken(secondary, 0.25),
        "tertiaryFixed": lighten(accent2, 0.55), "tertiaryFixedDim": accent2,
        "onTertiaryFixed": darken(accent2, 0.55), "onTertiaryFixedVariant": darken(accent2, 0.25),
        # terminal (latte-style: saturated mid-dark colours on the light bg)
        "term0": set_hls(bg, l=0.40), "term8": set_hls(bg, l=0.52),
        "term1": accent, "term9": darken(accent, 0.12),
        "term2": darken(accent2, 0.05), "term10": darken(accent2, 0.15),
        "term3": darken(mix(accent, accent2, 0.5), 0.05), "term11": darken(mix(accent, accent2, 0.5), 0.15),
        "term4": mix(accent2, accent, 0.5), "term12": darken(mix(accent2, accent, 0.5), 0.12),
        "term5": darken(accent, 0.08), "term13": darken(accent, 0.20),
        "term6": darken(mix(accent2, accent, 0.3), 0.08), "term14": darken(mix(accent2, accent, 0.3), 0.18),
        "term7": mix(set_hls(bg, l=0.68), accent, 0.06), "term15": set_hls(bg, l=0.76),
        # catppuccin-ish extras (latte-leaning for external app templates)
        "rosewater": darken(accent, 0.05), "flamingo": darken(accent, 0.12),
        "pink": mix(accent, "ffffff", 0.15), "mauve": mix(accent, accent2, 0.5),
        "red": accent, "maroon": darken(accent, 0.15), "peach": accent2,
        "yellow": darken(mix(accent2, "ffffff", 0.10), 0.05), "green": "38693c",
        "teal": mix(accent2, accent, 0.30), "sky": darken(mix(accent2, "ffffff", 0.15), 0.05),
        "sapphire": mix(accent, accent2, 0.40), "blue": darken(accent, 0.08),
        "lavender": lighten(mix(accent, accent2, 0.5), 0.10),
        "klink": accent, "klinkSelection": accent,
        "kvisited": darken(accent, 0.15), "kvisitedSelection": darken(accent, 0.15),
        "knegative": "ba1a1a", "knegativeSelection": "ba1a1a",
        "kneutral": accent2, "kneutralSelection": accent2,
        "kpositive": "38693c", "kpositiveSelection": "38693c",
        "text": text, "subtext1": set_hls(bg, l=0.30), "subtext0": grey,
        "overlay2": set_hls(bg, l=0.46),
        "overlay1": set_hls(bg, l=0.52),
        "overlay0": set_hls(bg, l=0.58),
        "surface2": darken(bg, 0.10), "surface1": darken(bg, 0.05), "surface0": darken(bg, 0.025),
        "base": bg, "mantle": darken(bg, 0.03), "crust": darken(bg, 0.06),
    }


def main():
    tpl = json.load(open(TEMPLATE))
    keys = list(tpl["colours"].keys())          # canonical key order + full set
    schemes_root = os.path.join(HERE, "schemes", "cumulus")
    state_root = os.path.join(HERE, "state")
    os.makedirs(state_root, exist_ok=True)

    for flavour, wall, mode, bg, accent, accent2 in PRESETS:
        palette = derive(mode, bg, accent, accent2)
        m = build_light(palette) if mode == "light" else build_dark(palette)
        # fill any template key we didn't map from the oldworld fallback (keeps files complete)
        colours = {k: m.get(k, tpl["colours"][k]).lstrip("#") for k in keys}

        d = os.path.join(schemes_root, flavour)
        os.makedirs(d, exist_ok=True)
        with open(os.path.join(d, f"{mode}.txt"), "w") as f:
            f.write("\n".join(f"{k} {v}" for k, v in colours.items()) + "\n")

        with open(os.path.join(state_root, f"{flavour}.json"), "w") as f:
            json.dump({"name": "cumulus", "flavour": flavour, "mode": mode,
                       "variant": "content", "colours": colours}, f)
        print(f"  {flavour:16s} {mode:5s} <- {wall}.jpg  accent #{accent}")

    # flavour -> wallpaper map, used by cumulus-scheme-cycle.sh's background
    # apply job to re-derive the wall for whatever state is newest
    with open(os.path.join(state_root, "wallmap.json"), "w") as f:
        json.dump({flavour: wall for flavour, wall, *_ in PRESETS}, f, indent=1)

    print(f"\nWrote {len(PRESETS)} presets to {schemes_root}")


if __name__ == "__main__":
    main()
