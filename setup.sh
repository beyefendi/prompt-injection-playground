#!/usr/bin/env bash

set -e  # exit on error

# ---- CONFIG ----
PYTHON_BIN="/opt/homebrew/bin/python3.13"

VENV_NAME=".venv"
KERNEL_NAME="prompt-injection-playground-notebook-env"

# langchan-core versions conflicts between spikee and llm-webmail;
# using constraints to force a compatible version.
REQUIREMENTS_FILE="requirements.txt"
CONSTRAINTS_FILE="constraints-langchain.txt"

# Clone targets
# llm-webmail on ReversecLabs is not up to date; using my repo instead 
SPIKEE_REPO="https://github.com/ReversecLabs/spikee.git"
LLM_WEBMAIL_REPO="https://github.com/beyefendi/llm-webmail.git"

SPIKEE_DIR="spikee"
LLM_WEBMAIL_DIR="llm-webmail"

# Local env config files (inside notebook-project)
SPIKEE_ENV_SRC="utils/.env-spikee"
LLM_WEBMAIL_ENV_SRC="utils/.env-llm-webmail"

WORKSPACE_ROOT=".."   # parent directory where repos will be cloned
WORKSPACE_DIR="workspace"
echo "=== Checking and cloning repositories ==="

cd "$WORKSPACE_ROOT"

# Clone spikee
if [ ! -d "$SPIKEE_DIR" ]; then
    echo "[!] Cloning spikee..."
    git clone "$SPIKEE_REPO"
    echo "[+] spikee cloned."
else
    echo "[!] spikee already exists — skipping clone."
fi

# Clone llm-webmail
if [ ! -d "$LLM_WEBMAIL_DIR" ]; then
    echo "[!] Cloning llm-webmail..."
    git clone -b feat --single-branch "$LLM_WEBMAIL_REPO"
    echo "[+] llm-webmail cloned."
else
    echo "[!] llm-webmail already exists — skipping clone."
fi

cd - > /dev/null  # return to notebook-project directory

echo -e "\n=== Copying environment config files ==="

# Copy .env for spikee
if [ -f "$SPIKEE_ENV_SRC" ]; then
    cp "$SPIKEE_ENV_SRC" "$WORKSPACE_ROOT/$SPIKEE_DIR/.env"
    echo "[+] Copied $SPIKEE_ENV_SRC → spikee/.env"
else
    echo "[x] WARNING: $SPIKEE_ENV_SRC not found — skipping."
fi

# Copy .env for llm-webmail
if [ -f "$LLM_WEBMAIL_ENV_SRC" ]; then
    cp "$LLM_WEBMAIL_ENV_SRC" "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/.env"
    echo "[+] Copied $LLM_WEBMAIL_ENV_SRC → llm-webmail/.env"
else
    echo "[x] WARNING: $LLM_WEBMAIL_ENV_SRC not found — skipping."
fi

echo -e "\n=== Creating virtual environment ==="
$PYTHON_BIN -m venv "$VENV_NAME"
source "$VENV_NAME/bin/activate"
echo "[+] Virtual environment created and activated."

echo -e "\n=== Upgrading pip ==="
"$VENV_NAME/bin/python3" -m pip install --upgrade pip

echo -e "\n=== Installing Jupyter kernel ==="
"$VENV_NAME/bin/python3" -m pip install ipykernel
echo "[+] Jupyter kernel installed in virtual environment."

echo -e "\n=== Registering Jupyter kernel ==="
"$VENV_NAME/bin/python3" -m ipykernel install --user --name "$KERNEL_NAME" --display-name "Notebook Env"

echo -e "\n=== Installing all project requirements into the .venv with constraints ==="
# Install spikee (editable) and llm-webmail requirements together so pip can resolve once,
# while forcing a compatible LangChain line via constraints to prevent accidental 1.x upgrades.
if [ -f "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/$REQUIREMENTS_FILE" ]; then
    
    if [ -f "$CONSTRAINTS_FILE" ]; then
        "$VENV_NAME/bin/python3" -m pip install -e "$WORKSPACE_ROOT/$SPIKEE_DIR" -r "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/$REQUIREMENTS_FILE" -c "$CONSTRAINTS_FILE"
    else
        echo "[!] constraints-langchain.txt not found; installing without constraints (not recommended)."
        "$VENV_NAME/bin/python3" -m pip install -e "$WORKSPACE_ROOT/$SPIKEE_DIR" -r "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/$REQUIREMENTS_FILE"
    fi
    echo "[+] Unified dependency installation complete."
else
    echo "[x] WARNING: llm-webmail requirements.txt not found."
fi

echo -e "\n=== llm-webmail Flask App Ready ==="

echo "[!] Please configure your local DNS: /etc/hosts file manually"
echo "sudo nano /etc/hosts"
echo "Add the following line to the hosts file"
echo "127.0.0.1   llmwebmail"

echo "[!] You can manually run it with:"
echo "  cd ../llm-webmail"
echo "  source ../prompt-injection-playground/.venv/bin/activate" # Activate the .venv in the prompt-injection-playground project (not llm-webmail)
echo "  FLASK_APP=app.py flask run --port=5001"
echo
echo "[!] (Not auto-starting Flask server to avoid blocking the script.)"

echo -e "\n=== Setting up workspace directory ==="
mkdir -p "$WORKSPACE_DIR"
if [ -f "utils/attacks.ipynb" ]; then
    cp "utils/attacks.ipynb" "$WORKSPACE_DIR/workspace.ipynb"
    echo "[+] Copied utils/attacks.ipynb → $WORKSPACE_DIR/workspace.ipynb"
else
    echo "[x] WARNING: utils/attacks.ipynb not found — skipping."
fi

echo -e "\n=== Setup complete! ==="
echo "[+] Jupyter kernel name:  $KERNEL_NAME"
echo "Navigate to the workspace folder in your VS Code and find the notebook to start working."

