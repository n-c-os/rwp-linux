#!/usr/bin/env bash
set -Eeuo pipefail
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
[[ "$(id -u)" == 0 ]] || { echo 'Utiliser sudo ./clean.sh' >&2; exit 1; }
if [[ -d "$HERE/work" ]]; then
  ( cd "$HERE/work" && lb clean )
  echo 'État de compilation nettoyé, configuration conservée.'
else
  echo 'Aucun build à nettoyer.'
fi
