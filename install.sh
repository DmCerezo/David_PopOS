#!/usr/bin/env bash
# install.sh — Reconstruye el entorno de trabajo sobre Pop!_OS.
#
# Idempotente: se puede ejecutar tantas veces como se quiera. Solo instala lo
# que falta y solo enlaza los dotfiles que aún no apuntan a este repositorio.
#
# Uso:
#   ./install.sh                 # todo: repos, apt, flatpak y dotfiles
#   ./install.sh apt dotfiles    # solo los pasos indicados
#   ./install.sh --dry-run       # muestra qué haría, sin cambiar nada
#   ./install.sh --help

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$REPO_DIR/packages"
DOTFILES_DIR="$REPO_DIR/dotfiles/home"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
ALL_STEPS=(repos apt flatpak dotfiles)
DRY_RUN=0

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[1;31m ✗\033[0m %s\n' "$*" >&2; exit 1; }

run() {
  if (( DRY_RUN )); then
    printf '   [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

usage() {
  sed -n '2,12p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Lee una lista de paquetes: un nombre por línea, ignora comentarios y vacías.
read_list() {
  sed -e 's/#.*//' -e 's/[[:space:]]*$//' -e '/^[[:space:]]*$/d' "$1"
}

check_system() {
  [[ $EUID -ne 0 ]] || die "No ejecutes este script como root; pedirá sudo cuando lo necesite."
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "pop" ]] || warn "Sistema detectado: ${PRETTY_NAME:-desconocido}. Pensado para Pop!_OS; continúo igualmente."
  fi
}

load_env() {
  # Variables opcionales (nombre/email de git, etc.). Nunca se versiona .env.
  if [[ -f "$REPO_DIR/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    . "$REPO_DIR/.env"
    set +a
  fi
}

# Repositorios apt de terceros: cada packages/apt/repos/<nombre>.sources es un
# fichero deb822 con una línea "# key: <url>" para su clave de firma. La clave
# se guarda en /etc/apt/keyrings/<nombre>.gpg (lo que indica Signed-By).
step_repos() {
  log "Repositorios apt de terceros"
  if ! command -v curl >/dev/null 2>&1 || ! command -v gpg >/dev/null 2>&1; then
    run sudo apt-get install -y curl gnupg
  fi
  local src name key_url uri keyring dest changed=0
  for src in "$PACKAGES_DIR"/apt/repos/*.sources; do
    [[ -e "$src" ]] || continue
    name="$(basename "$src" .sources)"
    keyring="/etc/apt/keyrings/$name.gpg"
    dest="/etc/apt/sources.list.d/$name.sources"
    key_url="$(sed -n 's/^# key: *//p' "$src" | head -1)"
    uri="$(sed -n 's/^URIs: *//p' "$src" | head -1)"
    # Si el repositorio ya está configurado (por nosotros o a mano, en .list o
    # .sources), no se toca: dos entradas con distinto Signed-By rompen apt.
    if grep -rqsF -- "${uri%/}" /etc/apt/sources.list.d/; then
      continue
    fi
    if [[ -n "$key_url" && ! -s "$keyring" ]]; then
      log "Descargando clave de $name"
      run sudo install -d -m 0755 /etc/apt/keyrings
      if (( ! DRY_RUN )); then
        local tmp
        tmp="$(mktemp)"
        curl -fsSL "$key_url" -o "$tmp" || die "No pude descargar la clave de $name ($key_url)"
        # Algunas claves vienen en ASCII (armored) y otras ya en binario.
        if grep -q -- '-----BEGIN PGP' "$tmp"; then
          gpg --dearmor --yes -o "$tmp.gpg" "$tmp" && mv "$tmp.gpg" "$tmp"
        fi
        sudo install -m 0644 "$tmp" "$keyring"
        rm -f "$tmp"
      fi
    fi
    run sudo install -m 0644 "$src" "$dest"
    ok "Repositorio $name configurado"
    changed=1
  done
  if (( changed )); then
    run sudo apt-get update
  else
    ok "Repositorios al día"
  fi
}

step_apt() {
  log "Paquetes apt"
  local missing=() pkg list
  for list in "$PACKAGES_DIR"/apt/*.list; do
    [[ -e "$list" ]] || continue
    while IFS= read -r pkg; do
      if dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q "install ok installed"; then
        continue
      fi
      missing+=("$pkg")
    done < <(read_list "$list")
  done

  if (( ${#missing[@]} == 0 )); then
    ok "Todos los paquetes apt ya están instalados"
    return
  fi
  log "Instalando ${#missing[@]} paquete(s): ${missing[*]}"
  run sudo apt-get update
  run sudo apt-get install -y "${missing[@]}"
}

step_flatpak() {
  log "Aplicaciones flatpak"
  if ! command -v flatpak >/dev/null 2>&1; then
    log "flatpak no está instalado; instalándolo"
    run sudo apt-get install -y flatpak
  fi
  # Pop!_OS ya trae flathub a nivel de sistema; --if-not-exists lo hace idempotente.
  run sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

  local installed app list count=0
  installed="$(flatpak list --app --columns=application 2>/dev/null || true)"
  for list in "$PACKAGES_DIR"/flatpak/*.list; do
    [[ -e "$list" ]] || continue
    while IFS= read -r app; do
      if grep -qx "$app" <<<"$installed"; then
        continue
      fi
      log "Instalando $app"
      run sudo flatpak install -y --noninteractive flathub "$app"
      count=$((count + 1))
    done < <(read_list "$list")
  done
  (( count > 0 )) || ok "Todas las aplicaciones flatpak ya están instaladas"
}

# Enlaza cada fichero de dotfiles/home en la misma ruta relativa de $HOME.
# Si ya existe un fichero distinto, se mueve a ~/.dotfiles-backup/<fecha>/.
step_dotfiles() {
  log "Dotfiles"
  local src rel dest
  while IFS= read -r -d '' src; do
    rel="${src#"$DOTFILES_DIR"/}"
    dest="$HOME/$rel"
    if [[ -L "$dest" && "$(readlink -f "$dest")" == "$(readlink -f "$src")" ]]; then
      continue
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
      run mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
      run mv "$dest" "$BACKUP_DIR/$rel"
      warn "Copia de seguridad: ~/$rel -> $BACKUP_DIR/$rel"
    fi
    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
    ok "Enlazado ~/$rel"
  done < <(find "$DOTFILES_DIR" -type f ! -name '.gitkeep' -print0)

  # Identidad de git fuera del repo: ~/.gitconfig.local (incluido por .gitconfig).
  if [[ -n "${GIT_USER_NAME:-}" && -n "${GIT_USER_EMAIL:-}" && ! -f "$HOME/.gitconfig.local" ]]; then
    log "Creando ~/.gitconfig.local con la identidad de .env"
    if (( ! DRY_RUN )); then
      git config --file "$HOME/.gitconfig.local" user.name "$GIT_USER_NAME"
      git config --file "$HOME/.gitconfig.local" user.email "$GIT_USER_EMAIL"
    fi
  fi
}

main() {
  local steps=()
  for arg in "$@"; do
    case "$arg" in
      -n|--dry-run) DRY_RUN=1 ;;
      -h|--help) usage; exit 0 ;;
      repos|apt|flatpak|dotfiles) steps+=("$arg") ;;
      *) die "Argumento desconocido: $arg (usa --help)" ;;
    esac
  done
  (( ${#steps[@]} )) || steps=("${ALL_STEPS[@]}")

  check_system
  load_env
  for step in "${steps[@]}"; do
    "step_$step"
  done
  ok "Listo"
}

main "$@"
