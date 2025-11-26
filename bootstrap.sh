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

simulations=$(cat << 'EOF'
1. All modes (Caution! Can take quite some time [20-40min])
2. Image N
3. Image LM
4. LSS N
5. LSS LM
6. IFU
EOF
)

echo ""
echo "========================================"
echo "Welcome to the METIS Pipeline installer!"
echo "========================================"
echo ""
echo "This script will clone the necessary git repositories, give you the option to install the uv package manager, as well as use it to install the pipeline dependencies. You are able to use the pipeline afterwards my executing: uv run --env-file .env 'your_command'"
echo ""
echo "Two questions before the installation:"
read -p "1. Do you want to automatically install uv? (It is needed for the installation)[y/n]: " uv_yesno
read -p "2. Do you wish to run METIS Simulations to create simulation data for the pipeline? (You can choose which one in the next step)[y/n]: " sim_yesno
case $sim_yesno in
	[Yy]|[Yy][Ee][Ss])
		echo ""
		printf "Which simulation modes would you like to run?\n$simulations\n"
		echo ""
		read -p "> " sim_num
		;;
	*)
		echo "No simulations selected"
		;;
esac
echo ""

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

echo ""
echo "Cloning METIS Pipeline and METIS Simulations: "
echo ""

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

echo ""
echo ".env written to $ENV_FILE"
echo ""

# Run uv sync to create the venv & install declared dependencies
case $uv_yesno in
	[Yy]|[Yy][Ee][Ss])
		echo "Installing uv:"
  		curl -LsSf https://astral.sh/uv/install.sh | sh
		;;
	*)
		echo "uv will not be installed"
		;;
esac

#source $HOME/.local/bin/env
echo "Running: uv sync"
echo ""

if command -v uv >/dev/null 2>&1; then
	uv sync
else
	. "$HOME/.local/bin/env"
	uv sync
fi

echo "Executing EDPS for the first time and editing config files"
echo "----------------------------------------------------------"
echo ""

uv run --env-file .env edps 
uv run --env-file .env edps -s > /dev/null 2>&1

sed -i "s|^workflow_dir=.*|workflow_dir=$TARGET_A/metisp/workflows|" "$HOME/.edps/application.properties"
sed -i "s|^esorex_path=.*|esorex_path=pyesorex|" "$HOME/.edps/application.properties"

case $sim_yesno in
	[Yy]|[Yy][Ee][Ss])
		env_dir=$(pwd)
		scripts="
		$TARGET_B/Simulations/python/imgLM.py
		$TARGET_B/Simulations/python/imgN.py
		$TARGET_B/Simulations/python/lssLM.py
		$TARGET_B/Simulations/python/lssN.py
		$TARGET_B/Simulations/python/ifu.py
		$TARGET_B/Simulations/python/calib.py
		"
		echo ""
		echo "Running simulations"
		echo "-------------------"
		echo ""
		echo "Downloading instrument packages: "
		echo ""
		(
			cd "$TARGET_B/Simulations" || exit 1
			uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/downloadPackages.py
			if [ $sim_num -eq "1" ]; then
				echo "Running all Simulations"
				echo "-----------------------"
				echo ""
				for s in $scripts; do
					uv run --project "$env_dir" --env-file $env_dir/.env python "$s"
				done
			elif [ $sim_num -eq "2" ]; then
				echo "Running Image N Simulations"
				echo "---------------------------"
				echo ""
				uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/imgN.py
			elif [ $sim_num -eq "3" ]; then
				echo "Running Image LM Simulations"
				echo "----------------------------"
				echo ""
				uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/imgLM.py
			elif [ $sim_num -eq "4" ]; then
				echo "Running LSS N Simulations"
				echo "-------------------------"
				echo ""
				uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/lssN.py
			elif [ $sim_num -eq "5" ]; then
				echo "Running LSS LM Simulations"
				echo "--------------------------"
				echo ""
				uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/lssLM.py
			elif [ $sim_num -eq "6" ]; then
				echo "Running IFU Simulations"
				echo "-----------------------"
				echo ""
				uv run --project "$env_dir" --env-file $env_dir/.env python $TARGET_B/Simulations/python/ifu.py
			fi
		)
		;;
	*)
		;;
esac

echo ""
echo "Bootstrap finished. To run commands inside the uv-managed environment with .env loaded:"
echo "uv run --env-file .env \$your_command"
echo " then use uv run to execute inside the project environment, e.g."
echo " uv run python -c \"import sys; print(sys.executable)\""

