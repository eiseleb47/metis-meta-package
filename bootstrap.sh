#!/usr/bin/env bash
# bootstrap.sh
# Bootstrap script for the project:
# - clones two METIS repositories into ./external/
# - exports build-time env vars needed before `uv sync`
# - runs `uv sync`
# - writes a .env file (with exports) for later use when running inside the uv-managed environment

set -euo pipefail
IFS=$'\n\t'

# Determine project root (directory containing this script)
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTERNAL_DIR="$ROOT_DIR/external"

REPO_A="https://github.com/AstarVienna/METIS_Pipeline.git"
REPO_B="https://github.com/AstarVienna/METIS_Simulations.git"
TARGET_A="$EXTERNAL_DIR/METIS_Pipeline"
TARGET_B="$EXTERNAL_DIR/METIS_Simulations"

# Make external dir
mkdir -p "$EXTERNAL_DIR"

clone_or_update() {
  local url="$1"
  local target="$2"

  if [ -d "$target/.git" ]; then
    echo "Updating existing repo at $target"
    git -C "$target" fetch --all --prune
    git -C "$target" pull --ff-only || true
  elif [ -d "$target" ]; then
    echo "Target exists but is not a git repo: $target"
  else
    echo "Cloning $url -> $target"
    git clone --depth 1 "$url" "$target"
  fi
}

# Clone or update both repos
clone_or_update "$REPO_A" "$TARGET_A"
clone_or_update "$REPO_B" "$TARGET_B"

# Export the build-time environment variables so they are visible to `uv sync` when run from this script
export PYCPL_RECIPE_DIR="$TARGET_A/metisp/pyrecipes/"
export PYESOREX_PLUGIN_DIR="$TARGET_A/metisp/pyrecipes/"

echo "Exported build-time variables:"
echo "  PYCPL_RECIPE_DIR=$PYCPL_RECIPE_DIR"
echo "  PYESOREX_PLUGIN_DIR=$PYESOREX_PLUGIN_DIR"

# Create a .env file for runtime use inside the uv-managed environment
ENV_FILE="$ROOT_DIR/.env"
cat > "$ENV_FILE" <<EOF
# .env — variables for running inside the uv-managed environment
# These lines are exported when this file is sourced by an interactive shell:
PYTHONPATH="$ROOT_DIR/external/METIS_Pipeline/metisp/pymetis/src/"
PYCPL_RECIPE_DIR="$ROOT_DIR/external/METIS_Pipeline/metisp/pyrecipes/"
PYESOREX_PLUGIN_DIR="$ROOT_DIR/external/METIS_Pipeline/metisp/pyrecipes/"
EOF

echo ".env written to $ENV_FILE"

# Run uv sync to create the venv & install declared dependencies
if command -v uv >/dev/null 2>&1; then
  echo "Running: uv sync"
  uv sync
else
  echo "Warning: 'uv' is not installed or not on PATH."
  echo "Install uv (e.g. 'python -m pip install --user uv' or use pipx) and re-run this script."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source $HOME/.env/bin/activate
  exit 1
fi

echo "Bootstrap finished. To run commands inside the uv-managed environment with .env loaded:"
echo "  # source the .env file to export runtime vars in your shell"
echo "  source \"$ENV_FILE\""
echo "  # then use uv run to execute inside the project environment, e.g."
echo "  uv run python -c \"import sys; print(sys.executable)\""

