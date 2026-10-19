# Guía de uso y mantenimiento

## 1. PC nuevo, de cero

1. Instala Pop!_OS y conéctate a internet.
2. Clona y ejecuta:

   ```bash
   sudo apt-get update && sudo apt-get install -y git
   git clone https://github.com/DmCerezo/David_PopOS.git ~/David_PopOS
   cd ~/David_PopOS
   cp .env.example .env        # pon GIT_USER_NAME y GIT_USER_EMAIL
   ./install.sh --dry-run      # revisa
   ./install.sh                # instala
   ```

3. Restaura a mano, desde tu copia de seguridad, lo que nunca va al repo:
   `~/.ssh/`, `~/.gnupg/`, tokens y el contenido de `.env`.
4. Abre una terminal nueva para cargar los alias.

`install.sh` pide `sudo` cuando lo necesita; no lo ejecutes como root.

## 2. Mantenerlo al día

```bash
cd ~/David_PopOS && ./update.sh
```

Hace, en este orden:

1. `git pull --ff-only` del repo (se lo salta si tienes cambios sin commit).
2. `apt-get update`, `full-upgrade` y `autoremove`.
3. `flatpak update`.
4. `./install.sh`: añade repos, paquetes y dotfiles nuevos de las listas.

Acepta `--dry-run` para ver qué haría.

## 3. Añadir un programa

| Tipo | Qué hacer |
|---|---|
| Paquete apt de Pop!_OS/Ubuntu | Añade el nombre a un `packages/apt/*.list` |
| App de Flathub | Añade su ID (p. ej. `org.gimp.GIMP`) a un `packages/flatpak/*.list` |
| Paquete de un repo externo | Crea `packages/apt/repos/<nombre>.sources` (ver abajo) y añade el paquete a una lista |
| Categoría nueva | Crea otro `.list`; se lee automáticamente |

Después: `./install.sh` (o `./install.sh apt` / `./install.sh flatpak`),
`git commit` y `git push`.

Si prefieres instalar primero a mano y apuntarlo después, usa
`./capture.sh`: escribe en `packages/*/captured.list` lo que tengas
instalado y no esté aún en ninguna lista. Revisa con `git diff`, mueve cada
línea a su categoría y haz commit.

### Formato de un repositorio externo

```
# key: https://ejemplo.com/clave.gpg
Types: deb
URIs: https://ejemplo.com/apt
Suites: stable
Components: main
Architectures: amd64
Signed-By: /etc/apt/keyrings/<nombre>.gpg
```

- La línea `# key:` es la URL de la clave de firma. `install.sh` la descarga
  (ASCII o binaria) a `/etc/apt/keyrings/<nombre>.gpg`.
- Si la URI ya está configurada en el sistema en cualquier fichero de
  `/etc/apt/sources.list.d/`, el repo se salta. Así no se duplica con el que
  instalan algunos programas por su cuenta (Chrome, VS Code).

## 4. Dotfiles

- Cualquier fichero en `dotfiles/home/` se enlaza en la misma ruta de `$HOME`.
  Para añadir uno: muévelo al repo y ejecuta `./install.sh dotfiles`.
- Si ya existe un fichero distinto, se guarda en `~/.dotfiles-backup/<fecha>/`.
- Antes de sustituir un `~/.gitconfig` propio, su `user.name`, `user.email` y
  `user.signingkey` se copian a `~/.gitconfig.local`, que nunca va al repo.
- Nada personal en `dotfiles/`: el repo es público.

Incluidos ahora:

- `.bash_aliases`: `ll`, `la`, `..`, `gs`, `gl`, `bat`/`fd` con sus nombres
  cortos y el hook de `direnv`.
- `.gitconfig`: rama `main` por defecto, `push.autoSetupRemote` y alias
  `st`, `co`, `br`, `lg`.

## 5. Secretos

- `.env` (copiado de `.env.example`) solo existe en tu PC.
- `.gitignore` bloquea `.env`, `*.local`, claves SSH/GPG y ficheros de tokens.
- gitleaks revisa cada commit (hook de pre-commit) y cada push (GitHub
  Actions); ver la sección del README.

## 6. Problemas habituales

| Síntoma | Solución |
|---|---|
| `No ejecutes este script como root` | Ejecútalo como tu usuario; pedirá `sudo` |
| `apt` falla con `Conflicting values set for option Signed-By` | Hay un repo duplicado en `/etc/apt/sources.list.d/`; borra uno de los dos ficheros |
| `No pude descargar la clave de …` | La URL de `# key:` cambió; actualízala en su `.sources` |
| Un flatpak no se encuentra | Comprueba el ID exacto en flathub.org |
| `update.sh` no hace `git pull` | Tienes cambios sin commit en el repo; haz commit o `git stash` |
| Git sin nombre/email tras instalar | Rellena `.env` y borra `~/.gitconfig.local`, o edítalo a mano |
