#!/usr/bin/env bash
# capture.sh — Guarda en el repositorio lo que tienes instalado en este PC.
#
# Escribe dos listas que install.sh lee como cualquier otra:
#   packages/apt/captured.list      paquetes apt instalados a mano
#   packages/flatpak/captured.list  aplicaciones flatpak
#
# Solo incluye lo que no esté ya en otra lista. Para apt descarta lo que venía
# con la instalación de Pop!_OS (/var/log/installer/initial-status.gz).
# Revisa el resultado con `git diff` y mueve cada paquete a la lista de su
# categoría si quieres. Solo guarda nombres de paquetes: nada sensible.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$REPO_DIR/packages"
BASELINE=/var/log/installer/initial-status.gz
# Paquetes de la instalación base de Pop!_OS que nunca interesa capturar.
BASE_PATTERN='^(lib|linux-|system76-|pop-|kernelstub|language-pack-|hunspell-|hyphen-|mythes-|thunderbird-locale-|ibus-|fonts-(arphic|noto-core|noto-ui)|gir1\.2-|python3(\.[0-9]+)?(-minimal)?$|python3-(apt|cffi-backend|dbus|gi|markdown-it|mdurl|netifaces|netplan|pkg-resources|pygments|typing-extensions|yaml)$|python-apt-common|netplan|systemd|dbus|w(american|brazilian|british|french|italian|ngerman|ogerman|portuguese|spanish|swiss)$|vim-(common|tiny)$|ubuntu-|gcc-[0-9]+-base$|(apt-utils|console-setup(-linux)?|cron(-daemon-common)?|debconf-i18n|dhcpcd-base|distro-info(-data)?|dmsetup|dosfstools|eject|init|iproute2|iputils-ping|iso-codes|kbd|keyboard-configuration|kmod|krb5-locales|logrotate|logsave|lsb-release|networkd-dispatcher|openssl|poppler-data|readline-common|rsyslog|shared-mime-info|sudo|udev|whiptail|xdg-user-dirs|xkb-data|xxd)$|$)'

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*" >&2; }

# Nombres ya presentes en las listas de una carpeta, salvo captured.list.
listed() {
  find "$PACKAGES_DIR/$1" -name '*.list' ! -name captured.list -print0 \
    | xargs -0 -r sed -e 's/#.*//' -e 's/[[:space:]]//g' -e '/^$/d' | sort -u
}

write_list() {
  local file="$1" header="$2" names="$3"
  {
    printf '# %s\n' "$header"
    printf '# Generado por capture.sh el %s. Revísalo antes de hacer commit.\n' "$(date +%F)"
    [[ -n "$names" ]] && printf '%s\n' "$names"
  } >"$file"
  ok "$(grep -vc '^#' "$file" || true) entrada(s) en ${file#"$REPO_DIR"/}"
}

capture_apt() {
  log "Paquetes apt instalados a mano"
  local manual baseline=""
  manual="$(apt-mark showmanual | sort -u)"
  if [[ -r "$BASELINE" ]]; then
    baseline="$(zcat "$BASELINE" | sed -n 's/^Package: //p' | sort -u)"
  else
    # Sin la lista de la instalación, descarta los paquetes de prioridad
    # required/important/standard y las familias que trae Pop!_OS de serie.
    warn "No encuentro $BASELINE; filtro la instalación base por prioridad y nombre."
    baseline="$(dpkg-query -W -f='${Package} ${Priority}\n' \
      | awk '$2 ~ /^(required|important|standard)$/ {print $1}')"
  fi
  local names
  names="$(comm -23 <(printf '%s\n' "$manual") \
    <(printf '%s\n%s\n' "$baseline" "$(listed apt)" | sort -u) \
    | grep -Ev "$BASE_PATTERN" || true)"
  write_list "$PACKAGES_DIR/apt/captured.list" "Paquetes apt capturados de este PC." "$names"

  local sources
  sources="$(find /etc/apt/sources.list.d -maxdepth 1 \( -name '*.list' -o -name '*.sources' \) \
    -printf '%f\n' 2>/dev/null | grep -Ev '^(system|pop-os-|ubuntu)' || true)"
  if [[ -n "$sources" ]]; then
    warn "Repositorios apt de terceros (algunos paquetes los necesitan):"
    while IFS= read -r s; do printf '     %s\n' "$s" >&2; done <<<"$sources"
  fi
}

capture_flatpak() {
  command -v flatpak >/dev/null 2>&1 || return 0
  log "Aplicaciones flatpak"
  local names
  names="$(comm -23 <(flatpak list --app --columns=application | sort -u) <(listed flatpak) || true)"
  write_list "$PACKAGES_DIR/flatpak/captured.list" "Aplicaciones flatpak capturadas de este PC." "$names"
}

main() {
  [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && { sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }
  capture_apt
  capture_flatpak
  log "Hecho. Revisa los cambios con: git -C \"$REPO_DIR\" diff"
}

main "$@"
