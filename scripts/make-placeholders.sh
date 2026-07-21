#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Generate placeholder artwork for assets/img/.
#
# Every file produced here is meant to be replaced. The filenames are what the
# site references, so keep them when you swap in real images:
#
#   favicon.svg   navbar/browser icon
#   logo.svg      navbar monogram
#   profile.svg   portrait on the home page  -> replace with a photo
#   og-image.svg  social preview             -> replace with a 1200x630 PNG
#                                               named og-image.png, which is
#                                               what assets/head.html points at
#   illustrations/*.svg  gallery items
#
# Usage:  bash scripts/make-placeholders.sh
# Safe to re-run; existing files are overwritten.
# ---------------------------------------------------------------------------
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
img="${root}/assets/img"
ill="${img}/illustrations"
mkdir -p "$ill"

accent="#1f6f9c"
signal="#b0741a"
paper="#eef2f5"
rule="#dce3e9"
ink="#4c5a66"

# -- favicon and logo: the monogram, nothing clever ------------------------
cat > "${img}/favicon.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" role="img" aria-label="NG">
  <rect width="64" height="64" rx="12" fill="${accent}"/>
  <text x="32" y="43" text-anchor="middle" font-family="system-ui, sans-serif"
        font-size="30" font-weight="700" fill="#ffffff">NG</text>
</svg>
SVG

cat > "${img}/logo.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 40 40" role="img" aria-label="NG monogram">
  <rect width="40" height="40" rx="8" fill="${accent}"/>
  <text x="20" y="27" text-anchor="middle" font-family="system-ui, sans-serif"
        font-size="17" font-weight="700" fill="#ffffff">NG</text>
</svg>
SVG

# -- portrait --------------------------------------------------------------
cat > "${img}/profile.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 480" role="img"
     aria-label="Portrait placeholder">
  <rect width="400" height="480" fill="${paper}"/>
  <circle cx="200" cy="185" r="72" fill="${rule}"/>
  <path d="M70 440c0-72 58-130 130-130s130 58 130 130z" fill="${rule}"/>
  <text x="200" y="466" text-anchor="middle" font-family="ui-monospace, monospace"
        font-size="13" fill="${ink}">replace with profile.jpg</text>
</svg>
SVG

# -- social preview --------------------------------------------------------
cat > "${img}/og-image.svg" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 630" role="img"
     aria-label="Natalia Gumińska, PhD">
  <rect width="1200" height="630" fill="#0e151c"/>
  <path d="M0 470 L120 470 L360 466 L600 468 L840 467 L1080 469 L1200 468"
        fill="none" stroke="${accent}" stroke-width="4"/>
  <path d="M600 468 L618 400 L636 468" fill="none" stroke="${signal}" stroke-width="5"/>
  <text x="90" y="250" font-family="system-ui, sans-serif" font-size="76"
        font-weight="700" fill="#e4ecf2">Natalia Gumińska, PhD</text>
  <text x="90" y="316" font-family="ui-monospace, monospace" font-size="30"
        fill="#9fb0bd">RNA biology · Research software · IIMCB Warsaw</text>
</svg>
SVG

# -- gallery placeholders --------------------------------------------------
make_tile () {
  local file="$1" label="$2" tint="$3"
  cat > "${ill}/${file}" <<SVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" role="img"
     aria-label="${label} placeholder">
  <rect width="800" height="600" fill="${paper}"/>
  <rect x="40" y="40" width="720" height="520" fill="none" stroke="${rule}"
        stroke-width="2" stroke-dasharray="8 8"/>
  <circle cx="400" cy="270" r="66" fill="none" stroke="${tint}" stroke-width="3"/>
  <path d="M340 330 L400 240 L460 330" fill="none" stroke="${tint}" stroke-width="3"/>
  <text x="400" y="420" text-anchor="middle" font-family="system-ui, sans-serif"
        font-size="26" font-weight="600" fill="${ink}">${label}</text>
  <text x="400" y="452" text-anchor="middle" font-family="ui-monospace, monospace"
        font-size="16" fill="${ink}">placeholder — replace this file</text>
</svg>
SVG
}

make_tile "abstract-ninetails.svg"    "Ninetails abstract"     "$accent"
make_tile "abstract-tailing.svg"      "Re-adenylation"         "$accent"
make_tile "abstract-euglena.svg"      "Intron removal order"   "$accent"
make_tile "figure-squiggle.svg"       "Anatomy of a squiggle"  "$signal"
make_tile "figure-pipeline.svg"       "Pipeline schematic"     "$signal"
make_tile "figure-distributions.svg"  "Tail distributions"     "$signal"
make_tile "art-01.svg"                "Digital art"            "$signal"
make_tile "art-02.svg"                "Digital art"            "$signal"
make_tile "art-03.svg"                "Digital art"            "$signal"

echo "Placeholders written to ${img}"
echo "Remember: assets/head.html references og-image.PNG, not the SVG."
