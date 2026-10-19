# David_PopOS

Mi entorno de trabajo sobre **Pop!_OS**, versionado para poder reconstruirlo
rápido en una instalación limpia: paquetes, aplicaciones, IDEs y dotfiles.

> ⚠️ Repositorio **público**. Aquí no se suben claves, tokens ni datos
> personales. Los secretos viven en `.env` (ignorado por git) y en ficheros
> `*.local` fuera del repositorio.

📚 Documentación:
[guía de uso y mantenimiento](docs/guia.md) ·
[programas incluidos](docs/programas.md)

## Reconstruir el entorno

En un Pop!_OS recién instalado:

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/DmCerezo/David_PopOS.git ~/David_PopOS
cd ~/David_PopOS
cp .env.example .env      # opcional: rellena tu nombre/email de git, etc.
./install.sh --dry-run    # revisa qué va a hacer
./install.sh              # instala todo
```

`install.sh` es idempotente: puedes volver a ejecutarlo cuando añadas algo a
las listas y solo instalará lo que falte.

También puedes ejecutar solo algunos pasos:

```bash
./install.sh repos        # repositorios apt de terceros
./install.sh apt          # paquetes apt
./install.sh flatpak      # aplicaciones de Flathub
./install.sh dotfiles     # enlaza los dotfiles en $HOME
```

## Mantenerlo al día

```bash
./update.sh               # git pull + actualiza apt y flatpak + ./install.sh
```

Un solo comando trae los últimos cambios del repo, actualiza todo lo instalado
e instala lo que se haya añadido a las listas.

## Guardar lo que tienes instalado

```bash
./capture.sh              # escribe packages/*/captured.list
git diff                  # revisa y mueve paquetes a su categoría si quieres
git commit -am "Actualiza paquetes" && git push
```

`capture.sh` apunta los paquetes apt instalados a mano (sin los que trae
Pop!_OS de serie) y las aplicaciones flatpak que aún no estén en ninguna lista.
Solo guarda nombres de paquetes. También avisa de los repositorios apt de
terceros que tengas, porque algunos paquetes los necesitan.

## Estructura

```
.
├── install.sh            # instala lo que falte (idempotente)
├── update.sh             # actualiza el sistema y el entorno
├── capture.sh            # guarda en las listas lo instalado en este PC
├── packages/
│   ├── apt/*.list        # paquetes apt por categoría
│   ├── apt/repos/        # repositorios apt de terceros
│   └── flatpak/*.list    # aplicaciones Flathub por categoría
├── dotfiles/
│   └── home/             # se enlaza tal cual sobre $HOME
├── docs/                 # guía y lista de programas
├── .github/workflows/    # escaneo de secretos en GitHub Actions
├── .pre-commit-config.yaml  # hook de gitleaks antes de cada commit
├── .env.example          # variables necesarias, sin valores
└── .gitignore            # excluye .env, claves SSH/GPG y tokens
```

### Listas de paquetes

Cada fichero `.list` contiene un paquete por línea; `#` inicia un comentario.
Para añadir una categoría nueva basta con crear otro `.list` en la carpeta
correspondiente: `install.sh` lee todos.

### Repositorios de terceros

Algunos programas (VS Code, Chrome, GitHub CLI, Node.js, Antigravity, Claude
Desktop) vienen de repositorios apt externos. Cada uno está en
`packages/apt/repos/<nombre>.sources`, con su clave en una línea `# key: <url>`.
`install.sh repos` añade solo los que no estén ya configurados en el sistema,
así que en un PC donde ya existen no toca nada. El de Claude Desktop es un
repositorio no oficial de la comunidad.

### Dotfiles

Todo lo que haya en `dotfiles/home/` se enlaza simbólicamente en la misma ruta
dentro de `$HOME` (por ejemplo `dotfiles/home/.config/foo/bar` →
`~/.config/foo/bar`). Si ya existía un fichero distinto, se mueve antes a
`~/.dotfiles-backup/<fecha>/`.

La identidad de git no está en el repo: `.gitconfig` incluye
`~/.gitconfig.local`. Si ya tenías un `~/.gitconfig` con tu nombre y email,
`install.sh` los copia ahí antes de sustituirlo; si no, lo crea a partir de
`GIT_USER_NAME` y `GIT_USER_EMAIL` en `.env`.

## Secretos

- Copia `.env.example` a `.env` y rellénalo solo en tu máquina.
- Las claves SSH y GPG se restauran a mano desde tu copia de seguridad; nunca
  se copian a este repositorio.
- `.gitignore` bloquea `.env`, `*.local`, claves SSH/GPG y ficheros de
  credenciales comunes, pero revisa siempre `git status` antes de un commit.

## Protección contra secretos

El repositorio usa [gitleaks](https://github.com/gitleaks/gitleaks) en dos puntos:

- **Antes de cada commit**, con un hook de [pre-commit](https://pre-commit.com) (`.pre-commit-config.yaml`) que revisa los cambios preparados.
- **En cada push y pull request**, con el workflow `.github/workflows/secret-scan.yml`, que escanea todo el historial y falla si encuentra algo.

### Activar el hook local

```bash
pipx install pre-commit      # o: sudo apt install pre-commit
pre-commit install           # una vez por clon
```

Desde ese momento, `git commit` se bloquea si gitleaks detecta un secreto. Para revisar todo el repositorio a mano:

```bash
pre-commit run gitleaks --all-files
```

La primera ejecución descarga Go y compila gitleaks, así que tarda un poco más.

### Si salta un aviso

- **Es un secreto real:** quítalo del commit, guárdalo fuera del repo (por ejemplo en un `.env` ignorado) y revócalo si ya llegó a GitHub, porque borrarlo del historial no basta.
- **Es un falso positivo:** añade la huella (`Fingerprint`) que muestra gitleaks a un fichero `.gitleaksignore` en la raíz, o marca la línea con el comentario `gitleaks:allow`.

Saltarse el hook con `git commit --no-verify` no evita el escaneo de GitHub Actions.
