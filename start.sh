#!/usr/bin/env bash
set -u

# ==============================================================================
# MEGA-CODE-4 - Portable launcher
# Redirects all runtime env to ./data and keeps host untouched.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
DATA_DIR="$ROOT_DIR/data"
HOME_DIR="$DATA_DIR/home"
CONFIG_HOME="$DATA_DIR/config"
APP_DATA="$DATA_DIR/app_data"
LOCAL_APP_DATA="$DATA_DIR/local_app_data"
CACHE_DIR="$DATA_DIR/cache"
LOG_DIR="$DATA_DIR/logs"
OC_DATA_DIR="$DATA_DIR/opencode"
ENV_FILE="$DATA_DIR/ai_settings.env"
SECURE_ENV="$ROOT_DIR/tools/secure_env.py"

mkdir -p "$HOME_DIR" "$CONFIG_HOME" "$APP_DATA" "$LOCAL_APP_DATA" "$CACHE_DIR" "$LOG_DIR" "$OC_DATA_DIR" "$ROOT_DIR/tools"

export HOME="$HOME_DIR"
export USERPROFILE="$HOME_DIR"
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$APP_DATA"
export XDG_CACHE_HOME="$CACHE_DIR"
export APPDATA="$APP_DATA"
export LOCALAPPDATA="$LOCAL_APP_DATA"
export PATH="$ROOT_DIR/tools:$PATH"

if [ -t 1 ]; then
  BOLD='\033[1m'; DIM='\033[2m'; CYAN='\033[36m'; GREEN='\033[32m'; RED='\033[31m'; YELLOW='\033[33m'; BLUE='\033[34m'; RESET='\033[0m';
else
  BOLD=''; DIM=''; CYAN=''; GREEN=''; RED=''; YELLOW=''; BLUE=''; RESET='';
fi

# ---------- crypto helpers ----------
ensure_crypto_tool() {
  [ -f "$SECURE_ENV" ] || {
    echo -e "${RED}[ERROR] Missing crypto helper: $SECURE_ENV${RESET}"
    exit 1
  }
}

prompt_master_password() {
  if [ -n "${MEGA_MASTER_PASSWORD:-}" ]; then
    MASTER_PASSWORD="$MEGA_MASTER_PASSWORD"
    return 0
  fi
  echo -e "${YELLOW}[~] Digite a Master Password para proteger o arquivo de credenciais.${RESET}"
  read -s -r MASTER_PASSWORD
  echo
  [ -n "$MASTER_PASSWORD" ] || { echo -e "${RED}[ERROR] Master Password vazia.${RESET}"; exit 1; }
}

load_encrypted_settings() {
  if [ ! -f "$ENV_FILE" ]; then
    return 0
  fi

  ensure_crypto_tool
  prompt_master_password

  local tmp
  tmp="$(mktemp)"
  python3 "$SECURE_ENV" --decrypt --input "$ENV_FILE" --output "$tmp" --password "$MASTER_PASSWORD" || {
    echo -e "${RED}[ERROR] Falha ao descriptografar $ENV_FILE${RESET}"
    exit 1
  }

  if [ -s "$tmp" ]; then
    set -a
    . "$tmp"
    set +a
  fi

  rm -f "$tmp"
}

save_encrypted_settings() {
  ensure_crypto_tool
  prompt_master_password

  local tmp
  tmp="$(mktemp)"
  {
    echo "# MEGA-CODE-4 settings"
    echo "COARENA_API_KEY=${COARENA_API_KEY:-}"
    echo "COARENA_BASE_URL=${COARENA_BASE_URL:-https://api.coarena.example/v1}"
    echo "COARENA_MODEL=${COARENA_MODEL:-Fable-5}"
    echo "AI_PROVIDER=${AI_PROVIDER:-coarena}"
    echo "OPENCODE_MODEL=${OPENCODE_MODEL:-coarena/Fable-5}"
    echo "MCP_HEXSTRIKE=${MCP_HEXSTRIKE:-0}"
    echo "MCP_CYBERSTRIKE=${MCP_CYBERSTRIKE:-0}"
  } > "$tmp"

  python3 "$SECURE_ENV" --encrypt --input "$tmp" --output "$ENV_FILE" --password "$MASTER_PASSWORD" || {
    echo -e "${RED}[ERROR] Falha ao cifrar credenciais.${RESET}"
    rm -f "$tmp"
    exit 1
  }
  chmod 600 "$ENV_FILE" 2>/dev/null || true
  rm -f "$tmp"
}

ensure_coarena_defaults() {
  export COARENA_BASE_URL="${COARENA_BASE_URL:-https://api.coarena.example/v1}"
  export COARENA_MODEL="${COARENA_MODEL:-Fable-5}"
  export COARENA_API_KEY="${COARENA_API_KEY:-}"
  export AI_PROVIDER="${AI_PROVIDER:-coarena}"
  export OPENCODE_MODEL="${OPENCODE_MODEL:-coarena/${COARENA_MODEL}}"
  export MCP_HEXSTRIKE="${MCP_HEXSTRIKE:-0}"
  export MCP_CYBERSTRIKE="${MCP_CYBERSTRIKE:-0}"
}

ascii_banner() {
  echo -e "${CYAN}"
  echo "  __  __   ___   ____   ____   _   _   ____  _____  ____   ____   ____  "
  echo " |  \\/  | / _ \\ / ___| / ___| | | | | / ___|| ____|/ ___| / ___||  _ \\ "
  echo " | |\\/| || | | |\\___ \\| |     | |_| | \\___ \\|  _|  \\___ \\| |    | |_) |"
  echo " | |  | || |_| | ___) | |___  |  _  |  ___) | |___  ___) | |___ |  __/ "
  echo " |_|  |_| \\___/ |____/ \\_____| |_| |_| |____/ |_____|____/ \\_____|_|    "
  echo -e "     ${BOLD}MEGA-CODE-4${RESET}${CYAN}"
  echo "     Portable Cyber Coding Agent"
  echo -e "${RESET}"
}

usage() {
  echo "Uso: ./start.sh [--dir PROJECT] [--setup] [--quick] [opencode args...]"
  echo ""
  echo "  --dir PROJECT   trabalha em outra pasta"
  echo "  --setup         configura Coarena e sai"
  echo "  --quick         inicia imediatamente"
  echo "  --help          mostra ajuda"
}

PROJECT_DIR="$PWD"
SETUP_ONLY=0
QUICK_MODE=0
PASS_ARGS=()

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)
      [ -n "${2:-}" ] || { echo -e "${RED}[ERROR] --dir precisa de um caminho${RESET}"; exit 1; }
      PROJECT_DIR="$2"
      shift 2
      ;;
    --dir=*)
      PROJECT_DIR="${1#*=}"
      shift
      ;;
    --setup)
      SETUP_ONLY=1
      shift
      ;;
    --quick)
      QUICK_MODE=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      PASS_ARGS+=("$1")
      shift
      ;;
  esac
done

[ -d "$PROJECT_DIR" ] || { echo -e "${RED}[ERROR] Diretório do projeto não encontrado: $PROJECT_DIR${RESET}"; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# Load any encrypted settings first; if the file doesn't exist, prompt the user to create it.
load_encrypted_settings
ensure_coarena_defaults

if [ ! -f "$ENV_FILE" ]; then
  echo -e "${YELLOW}[~] Nenhuma configuração cifrada encontrada. Configure a Coarena para continuar.${RESET}"
  prompt_master_password
  read -p "  URL da Coarena (ex.: https://api.coarena.example/v1): " COARENA_BASE_URL
  COARENA_BASE_URL="${COARENA_BASE_URL:-https://api.coarena.example/v1}"
  read -p "  Chave da API da Coarena: " COARENA_API_KEY
  read -p "  Modelo da Coarena (ex.: Fable-5): " COARENA_MODEL
  COARENA_MODEL="${COARENA_MODEL:-Fable-5}"
  AI_PROVIDER="coarena"
  OPENCODE_MODEL="coarena/${COARENA_MODEL}"
  MCP_HEXSTRIKE=0
  MCP_CYBERSTRIKE=0
  save_encrypted_settings
fi

# ---------- resolve OpenCode binary ----------
OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH="$(uname -m)"
case "$OS_NAME" in
    linux) PLATFORM="linux" ;;
    darwin) PLATFORM="darwin" ;;
    *)
        echo -e "${RED}[ERROR] Sistema operacional não suportado: $OS_NAME${RESET}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64) NODE_ARCH="x64" ;;
    arm64|aarch64) NODE_ARCH="arm64" ;;
    *)
        echo -e "${RED}[ERROR] Arquitetura não suportada: $ARCH${RESET}"
        exit 1
        ;;
esac

OC_BIN="$ROOT_DIR/engine/opencode-${PLATFORM}-${NODE_ARCH}/opencode"
[ -x "$OC_BIN" ] || {
  echo -e "${RED}[ERROR] OpenCode engine não encontrado em $OC_BIN${RESET}"
  exit 1
}

# ---------- render opencode config ----------
cat > "$HOME_DIR/.opencode.json" <<EOF
{
  "data": {
    "directory": "$OC_DATA_DIR"
  },
  "providers": {
    "coarena": {
      "apiKey": "${COARENA_API_KEY:-}",
      "baseURL": "${COARENA_BASE_URL:-https://api.coarena.example/v1}",
      "models": ["${COARENA_MODEL:-Fable-5}"]
    }
  },
  "agents": {
    "mega": {
      "model": "coarena/${COARENA_MODEL:-Fable-5}"
    }
  },
  "mcp": {
    "lazyLoad": true,
    "servers": {
      "hexstrike": {
        "enabled": ${MCP_HEXSTRIKE:-0},
        "host": "127.0.0.1",
        "port": 8889
      },
      "cyberstrike": {
        "enabled": ${MCP_CYBERSTRIKE:-0},
        "host": "127.0.0.1",
        "port": 8890
      }
    }
  }
}
EOF
chmod 600 "$HOME_DIR/.opencode.json" 2>/dev/null || true

ascii_banner

echo -e "${BLUE}=========================================================${RESET}"
echo -e "  ${BOLD}MEGA-CODE-4${RESET} ${DIM}- Portable Cyber Coding Agent${RESET}"
echo -e "${BLUE}=========================================================${RESET}"
echo -e "  ${BOLD}Engine${RESET}  : ${GREEN}$(basename "$OC_BIN")${RESET}"
echo -e "  ${BOLD}Model${RESET}   : ${GREEN}${COARENA_MODEL:-Fable-5}${RESET}"
echo -e "  ${BOLD}Project${RESET} : ${GREEN}${PROJECT_DIR}${RESET}"
echo -e "  ${BOLD}Data${RESET}    : ${DIM}${DATA_DIR}${RESET}"
echo -e "  ${BOLD}MCP${RESET}     : ${GREEN}[HexStrike ${MCP_HEXSTRIKE:-0}] [CyberStrike ${MCP_CYBERSTRIKE:-0}]${RESET}"
echo -e "  ${BOLD}Token${RESET}   : ${DIM}${MEGA_DASHBOARD_TOKEN:-generated-at-runtime}${RESET}"
echo -e "${BLUE}=========================================================${RESET}"

if [ "$SETUP_ONLY" -eq 1 ]; then
  echo -e "${GREEN}[OK] Configuração salva em $ENV_FILE${RESET}"
  exit 0
fi

echo ""
echo -e "  ${CYAN}[~] Iniciando OpenCode...${RESET}"
cd "$PROJECT_DIR" || exit 1
"$OC_BIN" "${PASS_ARGS[@]}"
STATUS=$?

echo ""
echo -e "  ${DIM}Dados da sessão: $OC_DATA_DIR${RESET}"
echo -e "  ${DIM}Código de saída: $STATUS${RESET}"
exit $STATUS
