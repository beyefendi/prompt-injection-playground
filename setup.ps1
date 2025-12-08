# PowerShell setup script for prompt-injection-playground
# Run with: powershell -ExecutionPolicy Bypass -File setup.ps1

$ErrorActionPreference = "Stop"

# ---- CONFIG ----
$PYTHON_BIN = "python.exe"  # Assumes python3.13 is in PATH or use full path

$VENV_NAME = ".venv"
$KERNEL_NAME = "prompt-injection-playground-notebook-env"

# langchain-core versions conflicts between spikee and llm-webmail;
# using constraints to force a compatible version.
$REQUIREMENTS_FILE = "requirements.txt"
$CONSTRAINTS_FILE = "constraints-langchain.txt"

# Clone targets
# llm-webmail on ReverseLabs is not up to date; using my repo instead 
$SPIKEE_REPO = "https://github.com/ReversecLabs/spikee.git"
$LLM_WEBMAIL_REPO = "https://github.com/beyefendi/llm-webmail.git"

$SPIKEE_DIR = "spikee"
$LLM_WEBMAIL_DIR = "llm-webmail"

# Local env config files (inside notebook-project)
$SPIKEE_ENV_SRC = "utils\.env-spikee"
$LLM_WEBMAIL_ENV_SRC = "utils\.env-llm-webmail"

$WORKSPACE_ROOT = ".."   # parent directory where repos will be cloned
$WORKSPACE_DIR = "workspace"

# ---- FUNCTIONS ----
function Write-Info {
    param([string]$Message)
    Write-Host "[!] $Message"
}

function Write-Success {
    param([string]$Message)
    Write-Host "[+] $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[x] $Message" -ForegroundColor Red
}

# ---- MAIN SCRIPT ----

Write-Host "`n=== Checking and cloning repositories ===" -ForegroundColor Cyan

Push-Location "$WORKSPACE_ROOT"

# Clone spikee
if (-not (Test-Path "$SPIKEE_DIR")) {
    Write-Info "Cloning spikee..."
    git clone "$SPIKEE_REPO"
    Write-Success "spikee cloned."
} else {
    Write-Info "spikee already exists -- skipping clone."
}

# Clone llm-webmail
if (-not (Test-Path "$LLM_WEBMAIL_DIR")) {
    Write-Info "Cloning llm-webmail..."
    git clone -b feat --single-branch "$LLM_WEBMAIL_REPO"
    Write-Success "llm-webmail cloned."
} else {
    Write-Info "llm-webmail already exists -- skipping clone."
}

Pop-Location  # return to notebook-project directory

Write-Host "`n=== Copying environment config files ===" -ForegroundColor Cyan

# Copy .env for spikee
if (Test-Path "$SPIKEE_ENV_SRC") {
    Copy-Item "$SPIKEE_ENV_SRC" "$WORKSPACE_ROOT/$SPIKEE_DIR/.env"
    Write-Success "Copied $SPIKEE_ENV_SRC -- $SPIKEE_DIR/.env"
} else {
    Write-Error-Custom "WARNING: $SPIKEE_ENV_SRC not found -- skipping."
}

# Copy .env for llm-webmail
if (Test-Path "$LLM_WEBMAIL_ENV_SRC") {
    Copy-Item "$LLM_WEBMAIL_ENV_SRC" "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/.env"
    Write-Success "Copied $LLM_WEBMAIL_ENV_SRC -- $LLM_WEBMAIL_DIR/.env"
} else {
    Write-Error-Custom "WARNING: $LLM_WEBMAIL_ENV_SRC not found -- skipping."
}

Write-Host "`n=== Creating virtual environment ===" -ForegroundColor Cyan
& $PYTHON_BIN -m venv "$VENV_NAME"
& ".\$VENV_NAME\Scripts\Activate.ps1"
Write-Success "Virtual environment created and activated."

Write-Host "`n=== Upgrading pip ===" -ForegroundColor Cyan
& ".\$VENV_NAME\Scripts\python.exe" -m pip install --upgrade pip

Write-Host "`n=== Installing Jupyter kernel ===" -ForegroundColor Cyan
& ".\$VENV_NAME\Scripts\python.exe" -m pip install ipykernel
Write-Success "Jupyter kernel installed in virtual environment."

Write-Host "`n=== Registering Jupyter kernel ===" -ForegroundColor Cyan
& ".\$VENV_NAME\Scripts\python.exe" -m ipykernel install --user --name "$KERNEL_NAME" --display-name "Notebook Env"

Write-Host "`n=== Installing all project requirements into the .venv with constraints ===" -ForegroundColor Cyan
# Install spikee (editable) and llm-webmail requirements together so pip can resolve once,
# while forcing a compatible LangChain version via constraints to prevent accidental 1.x upgrades.

$llmWebmailReqPath = "$WORKSPACE_ROOT/$LLM_WEBMAIL_DIR/$REQUIREMENTS_FILE"
if (Test-Path "$llmWebmailReqPath") {
    
    if (Test-Path "$CONSTRAINTS_FILE") {
        & ".\$VENV_NAME\Scripts\python.exe" -m pip install -e "$WORKSPACE_ROOT/$SPIKEE_DIR" -r "$llmWebmailReqPath" -c "$CONSTRAINTS_FILE"
    } else {
        Write-Info "constraints-langchain.txt not found; installing without constraints (not recommended)."
        & ".\$VENV_NAME\Scripts\python.exe" -m pip install -e "$WORKSPACE_ROOT/$SPIKEE_DIR" -r "$llmWebmailReqPath"
    }
    Write-Success "Unified dependency installation complete."
} else {
    Write-Error-Custom "WARNING: llm-webmail requirements.txt not found."
}

Write-Host "`n=== llm-webmail Flask App Ready ===" -ForegroundColor Cyan

Write-Info "Please configure your local DNS manually: C:\Windows\System32\drivers\etc\hosts"
Write-Info "Run Notepad as Administrator and add the following line:"
Write-Host "127.0.0.1   llmwebmail"

Write-Info "You can manually run Flask with:"
Write-Host "  cd ..\llm-webmail" -ForegroundColor Yellow
Write-Host "  .\..\prompt-injection-playground\.venv\Scripts\Activate.ps1" -ForegroundColor Yellow
Write-Host "  `$env:FLASK_APP='app.py'; flask run --port=5001" -ForegroundColor Yellow
Write-Host ""
Write-Info "(Not auto-starting Flask server to avoid blocking the script.)"

Write-Host "`n=== Setting up workspace directory ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path "$WORKSPACE_DIR" | Out-Null

if (Test-Path "utils/attacks.ipynb") {
    Copy-Item "utils/attacks.ipynb" "$WORKSPACE_DIR/workspace.ipynb"
    Write-Success "Copied utils/attacks.ipynb -- $WORKSPACE_DIR/workspace.ipynb"
} else {
    Write-Error-Custom "WARNING: utils/attacks.ipynb not found -- skipping."
}

Write-Host "`n=== Setup complete! ===" -ForegroundColor Green
Write-Success "Jupyter kernel name: $KERNEL_NAME"
Write-Host "Navigate to the workspace folder in your VS Code and find the notebook to start working." -ForegroundColor Cyan
