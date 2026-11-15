#!/usr/bin/env bash
set -Eeuo pipefail
iso="${1:-output/RWP-Linux-0.3-alpha-amd64.iso}"
[[ -f "$iso" ]] || { echo "ISO introuvable : $iso" >&2; exit 1; }
file "$iso"
if command -v xorriso >/dev/null 2>&1; then
  xorriso -indev "$iso" -report_el_torito plain
fi
sha256sum "$iso"
echo 'Cette vérification ne remplace pas un test de démarrage et une installation dans UTM.'
