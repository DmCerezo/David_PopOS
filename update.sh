#!/usr/bin/env bash
# update.sh — Pone al día el sistema y este entorno con un solo comando.
#
#   1. Trae los últimos cambios del repositorio (git pull).
#   2. Actualiza todos los paquetes apt y flatpak instalados.
#   3. Ejecuta install.sh para instalar lo nuevo de las listas y enlazar dotfiles.
#
# Uso:
#   ./update.sh              # todo
#   ./update.sh --dry-run    # muestra qué haría (se pasa también a install.sh)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*" >&2; }

main() {
  local dry=0
  for arg in "$@"; do
    case "$arg" in
      -n|--dry-run) dry=1 ;;
      -h|--help) sed -n '2,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
      *) printf 'Argumento desconocido: %s\n' "$arg" >&2; exit 1 ;;
    esac
  done
  run() { if (( dry )); then printf '   [dry-run] %s\n' "$*"; else "$@"; fi; }

  log "Repositorio"
  if [[ -n "$(git -C "$REPO_DIR" status --porcelain --untracked-files=no)" ]]; then
    warn "Hay cambios locales sin guardar; no hago git pull."
  else
    run git -C "$REPO_DIR" pull --ff-only
  fi

  log "Actualizando paquetes apt"
  run sudo apt-get update
  run sudo apt-get full-upgrade -y
  run sudo apt-get autoremove -y

  if command -v flatpak >/dev/null 2>&1; then
    log "Actualizando flatpak"
    run sudo flatpak update -y --noninteractive
  fi

  # Proceso nuevo: usa la versión de install.sh recién descargada.
  "$REPO_DIR/install.sh" "$@"
}

main "$@"
