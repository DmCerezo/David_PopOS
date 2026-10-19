# Programas del entorno

Inventario de lo que instala `install.sh`, sacado del PC actual (octubre de
2026) más unas utilidades básicas. La fuente de verdad son los ficheros de
`packages/`; si cambias algo allí, actualiza también esta tabla.

## Aplicaciones gráficas e IDEs

| Programa | Cómo se instala | Lista |
|---|---|---|
| Visual Studio Code | apt `code` (repo `vscode`) | `apt/dev.list` |
| Antigravity | apt `antigravity` (repo `antigravity`) | `apt/dev.list` |
| Android Studio | flatpak `com.google.AndroidStudio` | `flatpak/dev.list` |
| GitHub Desktop | flatpak `io.github.shiftey.Desktop` | `flatpak/dev.list` |
| Claude Desktop | apt `claude-desktop` (repo `claude-desktop`, **no oficial**) | `apt/desktop.list` |
| Google Chrome | apt `google-chrome-stable` (repo `google-chrome`) | `apt/desktop.list` |
| COSMIC Terminal | apt `cosmic-term` (repos de Pop!_OS) | `apt/desktop.list` |
| Steam | apt `steam-installer` | `apt/desktop.list` |
| OnlyOffice | flatpak `org.onlyoffice.desktopeditors` | `flatpak/productivity.list` |
| Discord | flatpak `com.discordapp.Discord` | `flatpak/productivity.list` |
| Hardware Monitor | flatpak `io.github.kai_j_g.HardwareMonitor` | `flatpak/productivity.list` |
| YapCap | flatpak `io.github.TopiCsarno.YapCap` | `flatpak/productivity.list` |
| Stremio | flatpak `com.stremio.Stremio` | `flatpak/multimedia.list` |
| OBS Studio | flatpak `com.obsproject.Studio` | `flatpak/multimedia.list` |

## Desarrollo (terminal)

| Paquete | Para qué |
|---|---|
| `git`, `git-lfs`, `gh` | Git, ficheros grandes y GitHub CLI (repo `github-cli`) |
| `nodejs` | Node.js 26 (repo `nodesource`) |
| `openjdk-21-jdk` | Java 21 |
| `build-essential`, `gcc-14`, `cmake`, `pkg-config` | Compilar C/C++ |
| `python3`, `python3-pip`, `python3-venv`, `pipx`, `python3-rich` | Python |
| `android-sdk-platform-tools-common` | Reglas udev para `adb` con móviles Android |
| `shellcheck` | Revisar scripts de shell |
| `direnv` | Variables de entorno por carpeta (`.envrc`) |

## Utilidades del sistema

`curl`, `wget`, `gnupg`, `ca-certificates`, `unzip`, `zip`, `htop`, `tree`,
`jq`, `ripgrep`, `fd-find`, `fzf`, `bat`, `tmux`, `vim`, `xclip`, `rsync`,
`netcat-openbsd`, `apt-transport-https`, `software-properties-common`,
`flatpak`, `ydotool`, `libinput-tools`, `fonts-noto-cjk`, `fonts-noto-cjk-extra`.

## Repositorios apt de terceros

Están en `packages/apt/repos/`. `install.sh` solo añade los que falten.

| Repo | Programas | Clave |
|---|---|---|
| `vscode` | VS Code | packages.microsoft.com |
| `google-chrome` | Chrome | dl.google.com |
| `github-cli` | `gh` | cli.github.com |
| `nodesource` | Node.js 26 | deb.nodesource.com |
| `antigravity` | Antigravity | us-central1-apt.pkg.dev |
| `claude-desktop` | Claude Desktop (comunidad, no oficial) | pkg.claude-desktop-debian.dev |

## Pendiente / notas del PC actual

- **GitHub Desktop** está instalado en el PC actual desde un `.deb` sin
  repositorio; el repo lo instala como flatpak. Para no tenerlo duplicado:
  `sudo apt remove github-desktop`.
- **Android Studio** está a la vez en `/opt/android-studio` y como flatpak; el
  repo solo mantiene el flatpak.
- **nvm** (Node 22 y 24) está instalado en el PC actual pero aún no lo gestiona
  el repo. Queda para la tanda de extras.
- VS Code no tiene extensiones instaladas todavía.
