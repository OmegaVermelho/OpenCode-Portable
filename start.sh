#!/bin/bash
# =================================================================
#  OpenCode Portable - Start (macOS/Linux)
#  Everything runs inside this folder. Nothing touches the host.
# =================================================================

CYAN='\033[36m'; GREEN='\033[32m'; YELLOW='\033[33m'; RED='\033[31m'
DIM='\033[90m'; BOLD='\033[1m'; RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$SCRIPT_DIR"
ENGINE_DIR="$ROOT_DIR/engine"
DATA_DIR="$ROOT_DIR/data"
ENV_FILE="$DATA_DIR/ai_settings.env"
HOME_DIR="$DATA_DIR/home"
CONFIG_HOME="$DATA_DIR/config"
CONFIG_FILE="$HOME_DIR/.opencode.json"
OC_DATA_DIR="$DATA_DIR/opencode"
LOG_DIR="$DATA_DIR/logs"

OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

case "$OS_NAME" in
    linux)  PLATFORM="linux" ;;
    darwin) PLATFORM="darwin" ;;
    *)
        echo -e "${RED}[ERROR] Unsupported OS: $OS_NAME${RESET}"
        exit 1
        ;;
esac

case "$ARCH" in
    x86_64|amd64) NODE_ARCH="x64" ;;
    arm64|aarch64) NODE_ARCH="arm64" ;;
    *)
        echo -e "${RED}[ERROR] Unsupported architecture: $ARCH${RESET}"
        exit 1
        ;;
esac

OC_BIN="$ENGINE_DIR/opencode-$PLATFORM-$NODE_ARCH/opencode"

PROJECT_DIR="$PWD"
PASS_ARGS=()
SETUP_ONLY=0
QUICK_MODE=0

usage() {
    echo "Usage: ./start.sh [--dir PROJECT] [--setup] [--quick] [opencode args...]"
    echo ""
    echo "  --dir PROJECT   Work on PROJECT instead of the current directory"
    echo "  --setup         Open the provider setup and exit"
    echo "  --quick         Launch immediately with the saved settings"
    echo "  --help          Show this help"
    echo ""
    echo "Any other argument is passed to opencode (ex: -p \"explain this repo\")."
}

while [ $# -gt 0 ]; do
    case "$1" in
        --dir)
            [ -z "${2:-}" ] && { echo -e "${RED}[ERROR] --dir needs a path${RESET}"; exit 1; }
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

[ -d "$PROJECT_DIR" ] || { echo -e "${RED}[ERROR] Project directory not found: $PROJECT_DIR${RESET}"; exit 1; }
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"

# ─── Portable environment ───────────────────────────────────
mkdir -p "$HOME_DIR" "$CONFIG_HOME" "$DATA_DIR/app_data" "$DATA_DIR/cache" \
         "$DATA_DIR/local_app_data" "$OC_DATA_DIR" "$LOG_DIR" "$ROOT_DIR/tools/bin"

export HOME="$HOME_DIR"
export USERPROFILE="$HOME"
export APPDATA="$DATA_DIR/app_data"
export LOCALAPPDATA="$DATA_DIR/local_app_data"
export XDG_CONFIG_HOME="$CONFIG_HOME"
export XDG_DATA_HOME="$DATA_DIR/app_data"
export XDG_CACHE_HOME="$DATA_DIR/cache"
export PATH="$ROOT_DIR/tools/bin:$PATH"

# ─── Settings ───────────────────────────────────────────────
load_settings() {
    [ -f "$ENV_FILE" ] || return 0
    while IFS='=' read -r key value; do
        key="${key%$'\r'}"
        value="${value%$'\r'}"
        [[ -z "$key" ]] && continue
        [[ "$key" == \#* ]] && continue
        export "$key=$value"
    done < "$ENV_FILE"
}

save_settings() {
    mkdir -p "$DATA_DIR"
    cat > "$ENV_FILE" <<EOF
# ========================================================
# OpenCode Portable - Provider Settings
# ========================================================
$1
EOF
    chmod 600 "$ENV_FILE" 2>/dev/null
}

mask_key() {
    local key="$1"
    if [ ${#key} -le 10 ]; then
        echo "********"
    else
        echo "${key:0:6}...${key: -4}"
    fi
}

verify_key() {
    local provider="$1" key="$2"
    command -v curl >/dev/null 2>&1 || return 0
    echo -e "  ${YELLOW}[~] Verifying API key...${RESET}"
    case "$provider" in
        anthropic)  curl -sf --max-time 15 -H "x-api-key: $key" -H "anthropic-version: 2023-06-01" https://api.anthropic.com/v1/models >/dev/null 2>&1 ;;
        openai)     curl -sf --max-time 15 -H "Authorization: Bearer $key" https://api.openai.com/v1/models >/dev/null 2>&1 ;;
        gemini)     curl -sf --max-time 15 "https://generativelanguage.googleapis.com/v1beta/models?key=$key" >/dev/null 2>&1 ;;
        openrouter) curl -sf --max-time 15 -H "Authorization: Bearer $key" https://openrouter.ai/api/v1/auth/key >/dev/null 2>&1 ;;
        groq)       curl -sf --max-time 15 -H "Authorization: Bearer $key" https://api.groq.com/openai/v1/models >/dev/null 2>&1 ;;
        xai)        curl -sf --max-time 15 -H "Authorization: Bearer $key" https://api.x.ai/v1/models >/dev/null 2>&1 ;;
    esac
}

pick_model() {
    local title="$1" default_model="$2"
    shift 2
    local -a items=("$@")
    local idx=1 model

    SELECTED_MODEL_IS_CUSTOM=0
    SELECTED_MODEL="$default_model"

    echo -e "  ${CYAN}--- $title ---${RESET}"
    for model in "${items[@]}"; do
        if [ "$model" = "$default_model" ]; then
            echo -e "  ${CYAN}${idx})${RESET} $model  ${GREEN}[default]${RESET}"
        else
            echo -e "  ${CYAN}${idx})${RESET} $model"
        fi
        idx=$((idx + 1))
    done
    echo -e "  ${CYAN}${idx})${RESET} ${DIM}Custom API model ID...${RESET}"
    echo ""
    read -p "  Choose a model (1-$idx) [Enter for default]: " MODEL_SEL
    [ -z "$MODEL_SEL" ] && MODEL_SEL=1
    if [ "$MODEL_SEL" = "$idx" ]; then
        read -p "  Enter the API model ID (ex: claude-sonnet-4-5): " SELECTED_MODEL
        [ -n "$SELECTED_MODEL" ] && SELECTED_MODEL_IS_CUSTOM=1
    else
        SELECTED_MODEL="${items[$((MODEL_SEL - 1))]}"
    fi
    if [ -z "$SELECTED_MODEL" ]; then
        SELECTED_MODEL="$default_model"
        SELECTED_MODEL_IS_CUSTOM=0
    fi
}

finalize_native_model() {
    local provider="$1" display_prefix="$2"
    OPENCODE_CUSTOM_MODEL=0
    OPENCODE_API_MODEL=""
    if [ "$SELECTED_MODEL_IS_CUSTOM" -eq 1 ]; then
        OPENCODE_CUSTOM_MODEL=1
        OPENCODE_API_MODEL="$SELECTED_MODEL"
        OPENCODE_MODEL="${provider}.${SELECTED_MODEL}"
        AI_DISPLAY_MODEL="${display_prefix} ${SELECTED_MODEL} (custom)"
    else
        OPENCODE_MODEL="$SELECTED_MODEL"
        AI_DISPLAY_MODEL="${display_prefix} ${SELECTED_MODEL}"
    fi
}

require_key() {
    local label="$1"
    read -p "  Enter your $label API key: " USER_API_KEY
    USER_API_KEY=$(echo "$USER_API_KEY" | tr -d ' ' | tr -d '\r')
    if [ -z "$USER_API_KEY" ]; then
        echo -e "  ${RED}[ERROR] Key cannot be empty!${RESET}"
        return 1
    fi
    echo -e "  ${DIM}Key: $(mask_key "$USER_API_KEY")${RESET}"
    return 0
}

# ─── Provider setup ─────────────────────────────────────────
setup_anthropic() {
    echo ""
    echo -e "  ${CYAN}=== ANTHROPIC CLAUDE ===${RESET}"
    require_key "Anthropic" || { setup_provider; return; }
    if ! verify_key anthropic "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_anthropic; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "CLAUDE MODELS" "claude-4-sonnet" \
        "claude-4-sonnet" "claude-4-opus" "claude-3.7-sonnet" \
        "claude-3.5-sonnet" "claude-3.5-haiku" "claude-3-opus" "claude-3-haiku"
    finalize_native_model "anthropic" "Anthropic"

    save_settings "AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_openai() {
    echo ""
    echo -e "  ${CYAN}=== OPENAI ===${RESET}"
    require_key "OpenAI" || { setup_provider; return; }
    if ! verify_key openai "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_openai; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "OPENAI MODELS" "gpt-4.1" \
        "gpt-4.1" "gpt-4.1-mini" "gpt-4.1-nano" "gpt-4.5-preview" \
        "gpt-4o" "gpt-4o-mini" "o3" "o3-mini" "o4-mini" "o1" "o1-pro" "o1-mini"
    finalize_native_model "openai" "OpenAI"

    save_settings "AI_PROVIDER=openai
OPENAI_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_gemini() {
    echo ""
    echo -e "  ${CYAN}=== GOOGLE GEMINI ===${RESET}"
    require_key "Gemini" || { setup_provider; return; }
    if ! verify_key gemini "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_gemini; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "GEMINI MODELS" "gemini-2.5" \
        "gemini-2.5" "gemini-2.5-flash" "gemini-2.0-flash" "gemini-2.0-flash-lite"
    finalize_native_model "gemini" "Google"

    save_settings "AI_PROVIDER=gemini
GEMINI_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_openrouter() {
    echo ""
    echo -e "  ${CYAN}=== OPENROUTER ===${RESET}"
    require_key "OpenRouter" || { setup_provider; return; }
    if ! verify_key openrouter "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_openrouter; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "OPENROUTER MODELS (compiled into this engine)" "openrouter.deepseek-r1-free" \
        "openrouter.deepseek-r1-free" "openrouter.claude-3.7-sonnet" "openrouter.claude-3.5-sonnet" \
        "openrouter.gpt-4.1" "openrouter.gpt-4.1-mini" "openrouter.o3-mini" "openrouter.o4-mini" \
        "openrouter.gemini-2.5" "openrouter.gemini-2.5-flash" "openrouter.claude-3.5-haiku" \
        "openrouter.claude-3-opus" "openrouter.gpt-4o" "openrouter.gpt-4o-mini"
    finalize_native_model "openrouter" "OpenRouter"

    save_settings "AI_PROVIDER=openrouter
OPENROUTER_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_groq() {
    echo ""
    echo -e "  ${CYAN}=== GROQ ===${RESET}"
    require_key "Groq" || { setup_provider; return; }
    if ! verify_key groq "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_groq; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "GROQ MODELS" "llama-3.3-70b-versatile" \
        "llama-3.3-70b-versatile" "meta-llama/llama-4-scout-17b-16e-instruct" \
        "meta-llama/llama-4-maverick-17b-128e-instruct" "deepseek-r1-distill-llama-70b" "qwen-qwq"
    finalize_native_model "groq" "Groq"

    save_settings "AI_PROVIDER=groq
GROQ_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_xai() {
    echo ""
    echo -e "  ${CYAN}=== XAI GROK ===${RESET}"
    require_key "xAI" || { setup_provider; return; }
    if ! verify_key xai "$USER_API_KEY"; then
        echo -e "  ${YELLOW}[WARN] Could not verify the key (offline or invalid).${RESET}"
        read -p "  Continue anyway? (y/N): " SAVE_ANYWAY
        [[ ! "$SAVE_ANYWAY" =~ ^[Yy]$ ]] && { setup_xai; return; }
    else
        echo -e "  ${GREEN}[OK] Key verified!${RESET}"
    fi
    pick_model "XAI MODELS" "grok-3-beta" \
        "grok-3-beta" "grok-3-mini-beta" "grok-3-fast-beta" "grok-3-mini-fast-beta"
    finalize_native_model "xai" "xAI"

    save_settings "AI_PROVIDER=xai
XAI_API_KEY=${USER_API_KEY}
OPENCODE_MODEL=${OPENCODE_MODEL}
OPENCODE_CUSTOM_MODEL=${OPENCODE_CUSTOM_MODEL}
OPENCODE_API_MODEL=${OPENCODE_API_MODEL}
AI_DISPLAY_MODEL=${AI_DISPLAY_MODEL}"
}

setup_local() {
    echo ""
    echo -e "  ${CYAN}=== LOCAL / CUSTOM OPENAI-COMPATIBLE ===${RESET}"
    echo "  Works with Ollama, LM Studio, DeepSeek, NVIDIA NIM, and any"
    echo "  server exposing GET /v1/models and POST /v1/chat/completions."
    echo ""
    echo "  Examples:"
    echo -e "    LM Studio  ${DIM}http://localhost:1234/v1${RESET}"
    echo -e "    Ollama     ${DIM}http://localhost:11434/v1${RESET}"
    echo -e "    DeepSeek   ${DIM}https://api.deepseek.com/v1${RESET}"
    echo -e "    NVIDIA NIM ${DIM}https://integrate.api.nvidia.com/v1${RESET}"
    echo ""
    read -p "  Base URL [http://localhost:1234/v1]: " LOCAL_ENDPOINT
    [ -z "$LOCAL_ENDPOINT" ] && LOCAL_ENDPOINT="http://localhost:1234/v1"
    LOCAL_ENDPOINT="${LOCAL_ENDPOINT%/}"

    read -p "  API key (Enter for none/local): " LOCAL_API_KEY
    LOCAL_API_KEY=$(echo "$LOCAL_API_KEY" | tr -d ' ' | tr -d '\r')
    [ -z "$LOCAL_API_KEY" ] && LOCAL_API_KEY="dummy"

    echo -e "  ${YELLOW}[~] Fetching models from ${LOCAL_ENDPOINT}/models...${RESET}"
    if command -v curl >/dev/null 2>&1; then
        MODELS=$(curl -sf --max-time 10 -H "Authorization: Bearer ${LOCAL_API_KEY}" "${LOCAL_ENDPOINT}/models" 2>/dev/null \
            | grep -Eo '"id"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | sed -e 's/"id"[[:space:]]*:[[:space:]]*"//g' -e 's/"//g' \
            | head -30)
    else
        MODELS=""
    fi

    if [ -z "$MODELS" ]; then
        echo -e "  ${YELLOW}[WARN] No models returned. Is the server running?${RESET}"
        read -p "  Enter the model ID manually (or leave empty to retry): " LOCAL_MODEL
        if [ -z "$LOCAL_MODEL" ]; then
            setup_local
            return
        fi
    else
        local idx=1 model
        local -a local_models=()
        echo -e "  ${CYAN}--- AVAILABLE MODELS ---${RESET}"
        while IFS= read -r model; do
            [ -z "$model" ] && continue
            echo -e "  ${CYAN}${idx})${RESET} $model"
            local_models[$idx]="$model"
            idx=$((idx + 1))
        done <<< "$MODELS"
        echo -e "  ${CYAN}${idx})${RESET} ${DIM}Manual model ID...${RESET}"
        echo ""
        read -p "  Choose a model (1-$idx) [Enter for 1]: " MODEL_SEL
        [ -z "$MODEL_SEL" ] && MODEL_SEL=1
        if [ "$MODEL_SEL" = "$idx" ]; then
            read -p "  Enter the model ID: " LOCAL_MODEL
        else
            LOCAL_MODEL="${local_models[$MODEL_SEL]}"
        fi
        [ -z "$LOCAL_MODEL" ] && LOCAL_MODEL="${local_models[1]}"
    fi

    save_settings "AI_PROVIDER=local
LOCAL_ENDPOINT=${LOCAL_ENDPOINT}
LOCAL_API_KEY=${LOCAL_API_KEY}
LOCAL_MODEL=${LOCAL_MODEL}
OPENCODE_MODEL=local.${LOCAL_MODEL}
OPENCODE_CUSTOM_MODEL=0
OPENCODE_API_MODEL=
AI_DISPLAY_MODEL=${LOCAL_MODEL} (local)"
}

setup_nvidia() {
    echo ""
    echo -e "  ${CYAN}=== NVIDIA NIM ===${RESET}"
    echo -e "  Free API keys: ${CYAN}https://build.nvidia.com${RESET}"
    echo ""
    while true; do
        if ! read -p "  Enter your NVIDIA API key (nvapi-...): " NVIDIA_KEY; then
            if [ -z "$NVIDIA_KEY" ]; then
                echo -e "  ${RED}[ERROR] Input closed.${RESET}"
                return 1
            fi
        fi
        NVIDIA_KEY=$(echo "$NVIDIA_KEY" | tr -d ' ' | tr -d '\r')
        [ -n "$NVIDIA_KEY" ] && break
        echo -e "  ${RED}[ERROR] Key cannot be empty!${RESET}"
    done
    echo -e "  ${DIM}Key: $(mask_key "$NVIDIA_KEY")${RESET}"
    echo ""
    echo -e "  ${YELLOW}[~] Fetching models...${RESET}"

    local -a curated=(
        "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning"
        "nvidia/nemotron-3-ultra-550b-a55b"
        "minimaxai/minimax-m3.1-flash"
        "deepseek-ai/deepseek-v4.1-flash"
    )
    local -a live=()
    if command -v curl >/dev/null 2>&1; then
        mapfile -t live < <(curl -sf --max-time 20 -H "Authorization: Bearer $NVIDIA_KEY" https://integrate.api.nvidia.com/v1/models 2>/dev/null \
            | grep -Eo '"id"[[:space:]]*:[[:space:]]*"[^"]*"' \
            | sed -e 's/"id"[[:space:]]*:[[:space:]]*"//g' -e 's/"//g')
    fi

    local -a nvidia_models=()
    local seen=" " model
    for model in "${curated[@]}" "${live[@]}"; do
        [ -z "$model" ] && continue
        case "$seen" in
            *" $model "*) continue ;;
        esac
        seen="$seen$model "
        nvidia_models+=("$model")
        [ ${#nvidia_models[@]} -ge 40 ] && break
    done

    if [ ${#nvidia_models[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[WARN] Could not fetch the model list.${RESET}"
        read -p "  Enter the NVIDIA model ID: " SELECTED_MODEL
        if [ -z "$SELECTED_MODEL" ]; then
            setup_nvidia
            return
        fi
    else
        pick_model "NVIDIA NIM MODELS" "${nvidia_models[0]}" "${nvidia_models[@]}"
    fi

    echo ""
    while true; do
        echo -e "  ${YELLOW}[~] Verifying key with a test completion...${RESET}"
        local test_body test_code test_resp
        test_body=$(curl -sS --connect-timeout 15 --max-time 90 -w $'\n%{http_code}' \
            -H "Authorization: Bearer $NVIDIA_KEY" -H "Content-Type: application/json" \
            -d "{\"model\":\"$SELECTED_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":8,\"stream\":false}" \
            https://integrate.api.nvidia.com/v1/chat/completions 2>&1)
        test_code=$(printf '%s' "$test_body" | tail -n1)
        test_resp=$(printf '%s' "$test_body" | sed '$d')

        if [ "$test_code" = "200" ]; then
            echo -e "  ${GREEN}[OK] Key verified!${RESET}"
            break
        fi
        if [ "$test_code" = "429" ]; then
            echo -e "  ${YELLOW}[WARN] Key accepted but rate-limited (HTTP 429).${RESET}"
            break
        fi
        if [ "$test_code" = "000" ]; then
            echo -e "  ${RED}[ERROR] Could not reach NVIDIA (network/DNS/proxy/timeout).${RESET}"
        else
            echo -e "  ${RED}[ERROR] NVIDIA rejected the test request (HTTP $test_code).${RESET}"
        fi
        [ -n "$test_resp" ] && echo -e "  ${DIM}$(printf '%s' "$test_resp" | head -c 300)${RESET}"

        case "$test_code" in
            000|5??)
                read -p "  Retry the test? (Y/n): " RETRY_NVIDIA
                if [[ "$RETRY_NVIDIA" =~ ^[Nn]$ ]]; then
                    echo -e "  ${YELLOW}[WARN] Saving without a verified key.${RESET}"
                    break
                fi
                ;;
            *)
                echo -e "  ${YELLOW}Check the key at https://build.nvidia.com and that the model has access.${RESET}"
                read -p "  Try another key/model? (Y/n): " RETRY_NVIDIA
                if [[ "$RETRY_NVIDIA" =~ ^[Nn]$ ]]; then
                    echo -e "  ${YELLOW}[WARN] Saving without a verified key.${RESET}"
                    break
                fi
                setup_nvidia
                return
                ;;
        esac
    done
    echo ""

    save_settings "AI_PROVIDER=local
LOCAL_ENDPOINT=https://integrate.api.nvidia.com/v1
LOCAL_API_KEY=${NVIDIA_KEY}
LOCAL_MODEL=${SELECTED_MODEL}
LOCAL_CAN_REASON=0
LOCAL_CONTEXT_WINDOW=131072
LOCAL_MAX_TOKENS=8192
OPENCODE_MODEL=local.${SELECTED_MODEL}
OPENCODE_CUSTOM_MODEL=0
OPENCODE_API_MODEL=
AI_DISPLAY_MODEL=NVIDIA ${SELECTED_MODEL}"
}

reset_provider_vars() {
    unset AI_PROVIDER ANTHROPIC_API_KEY OPENAI_API_KEY GEMINI_API_KEY OPENROUTER_API_KEY \
          GROQ_API_KEY XAI_API_KEY LOCAL_ENDPOINT LOCAL_API_KEY LOCAL_MODEL LOCAL_CAN_REASON \
          LOCAL_CONTEXT_WINDOW LOCAL_MAX_TOKENS OPENCODE_MODEL OPENCODE_CUSTOM_MODEL OPENCODE_API_MODEL AI_DISPLAY_MODEL
}

setup_provider() {
    reset_provider_vars
    echo ""
    echo -e "${CYAN}=========================================================${RESET}"
    echo -e "  ${BOLD}AI PROVIDER SELECTION${RESET}"
    echo -e "${CYAN}=========================================================${RESET}"
    echo ""
    echo -e "  ${CYAN}1)${RESET} ${BOLD}Anthropic Claude${RESET}  ${DIM}- Claude 4 / 3.7 / 3.5${RESET}"
    echo -e "  ${CYAN}2)${RESET} ${BOLD}OpenAI${RESET}            ${DIM}- GPT-4.1 / o3 / o4-mini${RESET}"
    echo -e "  ${CYAN}3)${RESET} ${BOLD}Google Gemini${RESET}     ${DIM}- Gemini 2.5 / 2.0${RESET}"
    echo -e "  ${CYAN}4)${RESET} ${BOLD}OpenRouter${RESET}        ${DIM}- many models, has a free tier${RESET}"
    echo -e "  ${CYAN}5)${RESET} ${BOLD}Groq${RESET}              ${DIM}- very fast inference${RESET}"
    echo -e "  ${CYAN}6)${RESET} ${BOLD}xAI Grok${RESET}          ${DIM}- Grok 3 models${RESET}"
    echo -e "  ${CYAN}7)${RESET} ${BOLD}NVIDIA NIM${RESET}        ${DIM}- free tier at build.nvidia.com${RESET}"
    echo -e "  ${CYAN}8)${RESET} ${BOLD}Local / Custom${RESET}    ${DIM}- Ollama, LM Studio, DeepSeek...${RESET}"
    echo ""

    while true; do
        read -p "  Select your provider (1-8): " PROVIDER_SEL
        case "$PROVIDER_SEL" in
            1) setup_anthropic; return ;;
            2) setup_openai; return ;;
            3) setup_gemini; return ;;
            4) setup_openrouter; return ;;
            5) setup_groq; return ;;
            6) setup_xai; return ;;
            7) setup_nvidia; return ;;
            8) setup_local; return ;;
            *) echo -e "  ${RED}[ERROR] Invalid selection. Please choose 1-8.${RESET}" ;;
        esac
    done
}

# ─── Config rendering ───────────────────────────────────────
json_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

render_config() {
    local provider_block="" agent_extra="" key="" extra=""
    case "$AI_PROVIDER" in
        anthropic)  key="$ANTHROPIC_API_KEY" ;;
        openai)     key="$OPENAI_API_KEY" ;;
        gemini)     key="$GEMINI_API_KEY" ;;
        openrouter) key="$OPENROUTER_API_KEY" ;;
        groq)       key="$GROQ_API_KEY" ;;
        xai)        key="$XAI_API_KEY" ;;
        local)
            key="${LOCAL_API_KEY:-dummy}"
            agent_extra=', "maxTokens": 8192'
            ;;
        *)
            echo -e "${RED}[ERROR] Unknown AI_PROVIDER: $AI_PROVIDER${RESET}"
            exit 1
            ;;
    esac

    if [ "${OPENCODE_CUSTOM_MODEL:-0}" = "1" ] && [ -n "${OPENCODE_API_MODEL:-}" ]; then
        extra=", \"models\": [\"$(json_escape "$OPENCODE_API_MODEL")\"]"
    fi
    provider_block="    \"$AI_PROVIDER\": { \"apiKey\": \"$(json_escape "$key")\"$extra }"

    mkdir -p "$HOME_DIR" "$OC_DATA_DIR"
    cat > "$CONFIG_FILE" <<EOF
{
  "data": {
    "directory": "$(json_escape "$OC_DATA_DIR")"
  },
  "providers": {
$provider_block
  },
  "agents": {
    "coder": { "model": "$(json_escape "$OPENCODE_MODEL")"$agent_extra },
    "summarizer": { "model": "$(json_escape "$OPENCODE_MODEL")"$agent_extra },
    "task": { "model": "$(json_escape "$OPENCODE_MODEL")"$agent_extra },
    "title": { "model": "$(json_escape "$OPENCODE_MODEL")" }
  },
  "autoCompact": true
}
EOF
    chmod 600 "$CONFIG_FILE" 2>/dev/null
}

# ─── Ollama helper ──────────────────────────────────────────
OLLAMA_PID=""
maybe_start_ollama() {
    [ "$AI_PROVIDER" = "local" ] || return 0
    [[ "$LOCAL_ENDPOINT" == *"11434"* ]] || return 0
    command -v ollama >/dev/null 2>&1 || return 0
    if curl -sf --max-time 2 "${LOCAL_ENDPOINT%/v1}/" >/dev/null 2>&1; then
        return 0
    fi
    echo -e "  ${CYAN}[~] Starting Ollama server...${RESET}"
    OLLAMA_MODELS="$DATA_DIR/ollama/data" ollama serve >>"$LOG_DIR/ollama.log" 2>&1 &
    OLLAMA_PID=$!
    sleep 3
    if curl -sf --max-time 3 "${LOCAL_ENDPOINT}" >/dev/null 2>&1; then
        echo -e "  ${GREEN}[OK] Ollama running!${RESET}"
    else
        echo -e "  ${YELLOW}[WARN] Ollama did not answer yet. See $LOG_DIR/ollama.log${RESET}"
    fi
}

cleanup() {
    if [ -n "$OLLAMA_PID" ]; then
        kill "$OLLAMA_PID" 2>/dev/null
        wait "$OLLAMA_PID" 2>/dev/null
    fi
}
trap cleanup EXIT

# ─── Main ───────────────────────────────────────────────────
load_settings

if [ "$SETUP_ONLY" -eq 1 ]; then
    if setup_provider; then
        echo ""
        echo -e "  ${GREEN}[OK] Settings saved!${RESET}"
        exit 0
    fi
    echo ""
    echo -e "  ${YELLOW}[WARN] Setup canceled.${RESET}"
    exit 1
fi

if [ -z "${AI_PROVIDER:-}" ] || [ -z "${OPENCODE_MODEL:-}" ]; then
    if ! setup_provider; then
        echo ""
        echo -e "  ${YELLOW}[WARN] Setup canceled.${RESET}"
        exit 1
    fi
    echo ""
    echo -e "  ${GREEN}[OK] Settings saved!${RESET}"
    echo ""
    load_settings
fi

if [ ! -x "$OC_BIN" ]; then
    echo -e "${RED}[ERROR] OpenCode engine not found for $PLATFORM-$NODE_ARCH.${RESET}"
    echo -e "${DIM}        Expected: $OC_BIN${RESET}"
    echo -e "${DIM}        Run tools/build_engine.sh to build it from ../opencode-main.${RESET}"
    exit 1
fi

render_config

PROVIDER_NAME="$AI_PROVIDER"
case "$AI_PROVIDER" in
    anthropic)  PROVIDER_NAME="Anthropic Claude" ;;
    openai)     PROVIDER_NAME="OpenAI" ;;
    gemini)     PROVIDER_NAME="Google Gemini" ;;
    openrouter) PROVIDER_NAME="OpenRouter" ;;
    groq)       PROVIDER_NAME="Groq" ;;
    xai)        PROVIDER_NAME="xAI Grok" ;;
    local)
        if [[ "${LOCAL_ENDPOINT:-}" == *integrate.api.nvidia.com* ]]; then
            PROVIDER_NAME="NVIDIA NIM"
        else
            PROVIDER_NAME="Local / Custom"
        fi
        ;;
esac

echo ""
echo -e "${CYAN}    ____                   __           __${RESET}"
echo -e "${CYAN}   / __ \\____  ____  ____/ /__  ____  / /____${RESET}"
echo -e "${CYAN}  / / / / __ \\/ __ \\/ __  / _ \\/ __ \\/ __/ _ \\${RESET}"
echo -e "${CYAN} / /_/ / /_/ / /_/ / /_/ /  __/ / / / /_/  __/${RESET}"
echo -e "${CYAN} \\____/ .___/\\____/\\__,_/\\___/_/ /_/\\__/\\___/${RESET}"
echo -e "${CYAN}     /_/${RESET}"
echo ""
echo -e "${CYAN}=========================================================${RESET}"
echo -e "  ${BOLD}OpenCode Portable${RESET} ${DIM}- zero footprint on the host${RESET}"
echo -e "${CYAN}=========================================================${RESET}"
echo ""
echo -e "  ${BOLD}Engine${RESET}  : ${GREEN}$(basename "$OC_BIN")${RESET}"
echo -e "  ${BOLD}Provider${RESET} : ${GREEN}${PROVIDER_NAME}${RESET}"
echo -e "  ${BOLD}Model${RESET}    : ${GREEN}${AI_DISPLAY_MODEL:-$OPENCODE_MODEL}${RESET}"
echo -e "  ${BOLD}Project${RESET}  : ${GREEN}${PROJECT_DIR}${RESET}"
echo -e "  ${BOLD}Data${RESET}     : ${DIM}${OC_DATA_DIR}${RESET}"
echo -e "${CYAN}=========================================================${RESET}"
echo ""

DEBUG_ARGS=()
if [ "$QUICK_MODE" -eq 1 ]; then
    LAUNCH_MODE=1
else
    while true; do
        echo -e "  ${BOLD}Select Action:${RESET}"
        echo -e "  ${CYAN}1)${RESET} ${GREEN}Launch OpenCode${RESET}            ${DIM}- TUI in ${PROJECT_DIR} (auto in 10s)${RESET}"
        echo -e "  ${CYAN}2)${RESET} Launch with Debug logging"
        echo -e "  ${CYAN}3)${RESET} Change Provider / Model / Key"
        echo -e "  ${CYAN}4)${RESET} Show portable environment"
        echo -e "  ${CYAN}5)${RESET} Exit"
        echo ""

        LAUNCH_MODE=""
        for i in {10..1}; do
            echo -ne "\r  Select action (1-5) [Auto in $i]: "
            if read -t 1 -n 1 LAUNCH_MODE; then
                break
            fi
        done
        if [ -z "$LAUNCH_MODE" ]; then
            LAUNCH_MODE="1"
            echo -ne "\r  Select action (1-5) [Auto in 0]: "
        fi
        echo ""

        case "$LAUNCH_MODE" in
            1) break ;;
            2) DEBUG_ARGS=(-d); break ;;
            3)
                if setup_provider; then
                    echo ""
                    echo -e "  ${GREEN}[OK] Settings saved!${RESET}"
                    load_settings
                    render_config
                    echo ""
                else
                    echo ""
                    echo -e "  ${YELLOW}[WARN] Setup canceled.${RESET}"
                fi
                ;;
            4)
                echo ""
                echo "  ROOT_DIR        : $ROOT_DIR"
                echo "  ENGINE          : $OC_BIN"
                echo "  HOME            : $HOME"
                echo "  XDG_CONFIG_HOME : $XDG_CONFIG_HOME"
                echo "  XDG_DATA_HOME   : $XDG_DATA_HOME"
                echo "  XDG_CACHE_HOME  : $XDG_CACHE_HOME"
                echo "  CONFIG_FILE     : $CONFIG_FILE"
                echo "  DATA_DIR        : $OC_DATA_DIR"
                echo ""
                ;;
            5) exit 0 ;;
            *) echo -e "  ${RED}[ERROR] Invalid selection.${RESET}" ; echo "" ;;
        esac
    done
fi

maybe_start_ollama

echo ""
echo -e "  ${CYAN}[~] Starting OpenCode...${RESET} ${DIM}(Ctrl+C to quit)${RESET}"
echo ""

cd "$PROJECT_DIR" || exit 1
"$OC_BIN" "${DEBUG_ARGS[@]}" "${PASS_ARGS[@]}"
STATUS=$?

echo ""
echo -e "  ${DIM}Session data: $OC_DATA_DIR/opencode.db${RESET}"
echo -e "  ${DIM}Exit code: $STATUS${RESET}"
exit $STATUS
