# David_PopOS

Entorno de trabajo reproducible basado en Pop!_OS: IDEs, herramientas de IA, programas y configuración, pensado para reconstruirse rápidamente.

> Repositorio público: no subas claves, tokens ni ningún dato sensible.

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
