# David_PopOS

Mi entorno de trabajo sobre **Pop!_OS**, versionado para poder reconstruirlo
rápido en una instalación limpia: paquetes, aplicaciones, IDEs y dotfiles.

> ⚠️ Repositorio **público**. Aquí no se suben claves, tokens ni datos
> personales. Los secretos viven en `.env` (ignorado por git) y en ficheros
> `*.local` fuera del repositorio.

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
./install.sh apt          # paquetes apt
./install.sh flatpak      # aplicaciones de Flathub
./install.sh dotfiles     # enlaza los dotfiles en $HOME
```

## Estructura

```
.
├── install.sh            # punto de entrada
├── packages/
│   ├── apt/*.list        # paquetes apt por categoría
│   └── flatpak/*.list    # aplicaciones Flathub por categoría
├── dotfiles/
│   └── home/             # se enlaza tal cual sobre $HOME
├── .github/workflows/    # escaneo de secretos en GitHub Actions
├── .pre-commit-config.yaml  # hook de gitleaks antes de cada commit
├── .env.example          # variables necesarias, sin valores
└── .gitignore            # excluye .env, claves SSH/GPG y tokens
```

### Listas de paquetes

Cada fichero `.list` contiene un paquete por línea; `#` inicia un comentario.
Para añadir una categoría nueva basta con crear otro `.list` en la carpeta
correspondiente: `install.sh` lee todos.

### Dotfiles

Todo lo que haya en `dotfiles/home/` se enlaza simbólicamente en la misma ruta
dentro de `$HOME` (por ejemplo `dotfiles/home/.config/foo/bar` →
`~/.config/foo/bar`). Si ya existía un fichero distinto, se mueve antes a
`~/.dotfiles-backup/<fecha>/`.

La identidad de git no está en el repo: `.gitconfig` incluye
`~/.gitconfig.local`, que `install.sh` crea a partir de `GIT_USER_NAME` y
`GIT_USER_EMAIL` en `.env` si no existe.

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
