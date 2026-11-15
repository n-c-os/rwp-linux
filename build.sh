#!/usr/bin/env bash
set -Eeuo pipefail

# RWP Linux 0.3 Alpha: Debian 13 amd64 Live + Debian Installer (live mode)
# Exécuter sur Debian 13 amd64 avec réseau et au moins 20 Gio libres.
HERE="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORK="$HERE/work"
OUT="$HERE/output"
ISO="$OUT/RWP-Linux-0.3-alpha-amd64.iso"

error() { printf 'Erreur : %s\n' "$*" >&2; exit 1; }
[[ "$(id -u)" -eq 0 ]] || error 'Exécuter avec sudo : sudo ./build.sh'
[[ "$(uname -m)" == "x86_64" ]] || error 'Utiliser Debian amd64 (x86_64) pour ce build.'
[[ -r /etc/os-release ]] || error 'Impossible de déterminer le système.'
. /etc/os-release
[[ "${ID:-}" == debian && "${VERSION_CODENAME:-}" == trixie ]] || error 'Build prévu pour Debian 13 Trixie.'
command -v curl >/dev/null || error "Installer curl : apt install curl"
command -v apt-get >/dev/null || error 'apt-get introuvable.'

printf '== Vérification accès dépôts Debian ==\n'
curl --fail --silent --show-error --location --connect-timeout 15 --max-time 35 \
    https://deb.debian.org/debian/dists/trixie/Release --output /dev/null \
    || error 'Pas de connexion aux dépôts Debian (vérifier Internet/DNS).'

printf '== Dépendances de construction ==\n'
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  live-build debootstrap squashfs-tools xorriso isolinux syslinux-common \
  grub-efi-amd64-bin mtools dosfstools ca-certificates curl gnupg

# Vérifier les noms de paquets avant de lancer le chroot/debootstrap.
# Les listes sont celles de config/package-lists/, avec commentaires ignorés.
printf '== Pré-vérification des paquets Debian ==\n'
missing=0
for list in "$HERE"/config/package-lists/*.list.chroot*; do
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    pkg="${pkg%%#*}"
    pkg="$(printf '%s' "$pkg" | xargs)"
    [[ -z "$pkg" ]] && continue
    if ! apt-cache show "$pkg" >/dev/null 2>&1; then
      printf 'PAQUET INTROUVABLE : %s (%s)\n' "$pkg" "$(basename "$list")" >&2
      missing=1
    fi
  done < "$list"
done
(( missing == 0 )) || error 'Corriger les paquets avant de poursuivre la compilation.'

[[ ! -e "$WORK/.build" ]] || error 'Build déjà présent : lancer sudo ./clean.sh avant de recommencer.'
mkdir -p "$WORK" "$OUT"
cd "$WORK"

printf '== Configuration Debian Live ==\n'
lb config \
  --distribution trixie \
  --architectures amd64 \
  --binary-image iso-hybrid \
  --bootloaders "syslinux,grub-efi" \
  --debian-installer live \
  --debian-installer-gui true \
  --archive-areas "main contrib non-free-firmware" \
  --bootappend-live "boot=live components username=rwp hostname=rwp-linux locales=fr_FR.UTF-8 keyboard-layouts=fr" \
  --iso-volume "RWP_LINUX_03_AMD64"

# Les listes et inclusions sont communes à la session Live et au système installé.
cp -a "$HERE/config/." "$WORK/config/"

printf '== Construction de l ISO (journal build.log) ==\n'
set +e
lb build 2>&1 | tee "$OUT/build.log"
status=${PIPESTATUS[0]}
set -e
[[ $status -eq 0 ]] || error "Échec du build (voir $OUT/build.log)."

if [[ -f "$WORK/live-image-amd64.hybrid.iso" ]]; then
  cp -f "$WORK/live-image-amd64.hybrid.iso" "$ISO"
else
  mapfile -t matches < <(find "$WORK" -maxdepth 1 -type f -name '*.iso' -print)
  [[ ${#matches[@]} == 1 ]] || error 'Build terminé mais ISO introuvable ou ambiguë.'
  cp -f "${matches[0]}" "$ISO"
fi
( cd "$OUT" && sha256sum "$(basename "$ISO")" > "$(basename "$ISO").sha256" )
printf '\nISO produite : %s\n' "$ISO"
ls -lh "$ISO"
if command -v xorriso >/dev/null; then
  xorriso -indev "$ISO" -report_el_torito plain > "$OUT/boot-report.txt" 2>&1 || true
  echo "Rapport boot : $OUT/boot-report.txt"
fi
printf 'ATTENTION : vérifier ensuite le démarrage et l installation dans une VM jetable.\n'
