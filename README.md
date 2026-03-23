# METIS Pipeline Installer

<p align="center">
  <a href="https://github.com/eiseleb47/metis-meta-package/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/eiseleb47/metis-meta-package/ci.yml?branch=master&label=CI&style=for-the-badge&labelColor=1e1e2e&color=a6e3a1&logo=github&logoColor=cdd6f4" alt="CI"></a>
  <a href="https://www.python.org/"><img src="https://img.shields.io/badge/python-3.11–3.13-89b4fa?style=for-the-badge&labelColor=1e1e2e&logo=python&logoColor=cdd6f4" alt="Python"></a>
  <a href="https://github.com/eiseleb47/metis-meta-package/commits/master"><img src="https://img.shields.io/github/last-commit/eiseleb47/metis-meta-package?style=for-the-badge&labelColor=1e1e2e&color=cba6f7&logo=git&logoColor=cdd6f4" alt="Last Commit"></a>
  <a href="#"><img src="https://img.shields.io/badge/platform-linux%20%7C%20macos-fab387?style=for-the-badge&labelColor=1e1e2e&logo=linux&logoColor=cdd6f4" alt="Platform"></a>
</p>

A one-command installer for the ESO stack required by the [METIS Pipeline](https://github.com/AstarVienna/METIS_Pipeline). Installs `pycpl`, `pyesorex`, `edps`, `adari_core`, `scopesim`, and `scopesim_templates` into a `uv`-managed environment, and configures EDPS automatically.

## Installation

Clone the repository and run the bootstrap script:

```bash
git clone https://github.com/eiseleb47/metis-meta-package
cd metis-meta-package
./bootstrap.sh
```

The script will:
1. Clone [METIS_Pipeline](https://github.com/AstarVienna/METIS_Pipeline) and [METIS_Simulations](https://github.com/AstarVienna/METIS_Simulations) into `~/`
2. Install all Python dependencies via `uv sync`
3. Initialise and configure EDPS (port 4444, workflow dir, esorex path)
4. Write a `.env` file with the required environment variables

> When EDPS asks for a bookkeeping directory, press **Enter** to use the default.

## Usage

All commands must be run from inside this directory, prefixed with `uv run --env-file .env`:

```bash
# List available pipeline recipes
uv run --env-file .env pyesorex --recipes

# Check available EDPS workflows
uv run --env-file .env edps -P 4444 -lw

# Run a custom Python script in the managed environment
uv run --env-file .env python my_script.py
```

## Related Repositories

- **[METIS_Pipeline](https://github.com/AstarVienna/METIS_Pipeline)** — the core Python/C pipeline, EDPS workflows, and PyEsoRex recipes
- **[METIS_Simulations](https://github.com/AstarVienna/METIS_Simulations)** — ScopeSim scripts that generate synthetic FITS observations for each observing mode
- **[MTR](https://github.com/eiseleb47/MTR)** — end-to-end test runner that combines simulation + pipeline reduction in one command
