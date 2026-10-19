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
