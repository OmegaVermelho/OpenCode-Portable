@echo off
setlocal EnableDelayedExpansion
title OpenCode Portable

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "ENGINE_DIR=%ROOT_DIR%\engine"
set "DATA_DIR=%ROOT_DIR%\data"
set "ENV_FILE=%DATA_DIR%\ai_settings.env"
set "HOME_DIR=%DATA_DIR%\home"
set "CONFIG_HOME=%DATA_DIR%\config"
set "CONFIG_FILE=%HOME_DIR%\.opencode.json"
set "OC_DATA_DIR=%DATA_DIR%\opencode"
set "LOG_DIR=%DATA_DIR%\logs"
set "OC_BIN=%ENGINE_DIR%\opencode-windows-x64\opencode.exe"

set "PROJECT_DIR=%CD%"
set "SETUP_ONLY=0"

:parse_args
if "%~1"=="" goto args_done
if /i "%~1"=="--setup" (
    set "SETUP_ONLY=1"
    shift
    goto parse_args
)
if /i "%~1"=="--dir" (
    if not "%~2"=="" set "PROJECT_DIR=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="--help" goto show_help
shift
goto parse_args

:show_help
echo Usage: START.bat [--dir PROJECT] [--setup]
echo.
echo   --dir PROJECT   Work on PROJECT instead of the current directory
echo   --setup         Open the provider setup and exit
echo.
pause
exit /b 0

:args_done
if not exist "%OC_BIN%" (
    for /d %%D in ("%ENGINE_DIR%\opencode-*") do (
        if exist "%%D\opencode.exe" set "OC_BIN=%%D\opencode.exe"
    )
)
if not exist "!OC_BIN!" (
    echo [ERROR] OpenCode engine not found.
    echo         Expected: %ENGINE_DIR%\opencode-windows-x64\opencode.exe
    echo         Run tools\build_engine.sh from a machine with Go to build it.
    pause
    exit /b 1
)
if not exist "!PROJECT_DIR!" (
    echo [ERROR] Project directory not found: !PROJECT_DIR!
    pause
    exit /b 1
)

mkdir "%HOME_DIR%" 2>nul
mkdir "%CONFIG_HOME%" 2>nul
mkdir "%DATA_DIR%\app_data" 2>nul
mkdir "%DATA_DIR%\local_app_data" 2>nul
mkdir "%DATA_DIR%\cache" 2>nul
mkdir "%OC_DATA_DIR%" 2>nul
mkdir "%LOG_DIR%" 2>nul
mkdir "%ROOT_DIR%\tools\bin" 2>nul

set "HOME=%HOME_DIR%"
set "USERPROFILE=%HOME_DIR%"
set "APPDATA=%DATA_DIR%\app_data"
set "LOCALAPPDATA=%DATA_DIR%\local_app_data"
set "XDG_CONFIG_HOME=%CONFIG_HOME%"
set "XDG_DATA_HOME=%DATA_DIR%\app_data"
set "XDG_CACHE_HOME=%DATA_DIR%\cache"
set "PATH=%ROOT_DIR%\tools\bin;%PATH%"

:main
if exist "%ENV_FILE%" (
    for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
        if not "%%A"=="" set "%%A=%%B"
    )
)
if not defined OPENCODE_CUSTOM_MODEL set "OPENCODE_CUSTOM_MODEL=0"
if not defined AI_PROVIDER goto setup_provider
if not defined OPENCODE_MODEL goto setup_provider
goto main_ready

rem ============================================================
rem  Provider setup
rem ============================================================
:setup_provider
set "ANTHROPIC_API_KEY="
set "OPENAI_API_KEY="
set "GEMINI_API_KEY="
set "OPENROUTER_API_KEY="
set "GROQ_API_KEY="
set "XAI_API_KEY="
set "LOCAL_ENDPOINT="
set "LOCAL_API_KEY="
set "LOCAL_MODEL="
set "LOCAL_CAN_REASON="
set "LOCAL_CONTEXT_WINDOW="
set "LOCAL_MAX_TOKENS="
set "OPENCODE_MODEL="
set "OPENCODE_CUSTOM_MODEL=0"
set "OPENCODE_API_MODEL="
set "AI_DISPLAY_MODEL="
echo.
echo =========================================================
echo   AI PROVIDER SELECTION
echo =========================================================
echo.
echo   1) Anthropic Claude   - Claude 4 / 3.7 / 3.5
echo   2) OpenAI             - GPT-4.1 / o3 / o4-mini
echo   3) Google Gemini      - Gemini 2.5 / 2.0
echo   4) OpenRouter         - many models, has a free tier
echo   5) Groq               - very fast inference
echo   6) xAI Grok           - Grok 3 models
echo   7) NVIDIA NIM         - free tier at build.nvidia.com
echo   8) Local / Custom     - Ollama, LM Studio, DeepSeek...
echo.
choice /c 12345678 /n /m "  Select your provider (1-8): "
if errorlevel 8 goto setup_local
if errorlevel 7 goto setup_nvidia
if errorlevel 6 goto setup_xai
if errorlevel 5 goto setup_groq
if errorlevel 4 goto setup_openrouter
if errorlevel 3 goto setup_gemini
if errorlevel 2 goto setup_openai
if errorlevel 1 goto setup_anthropic
goto setup_provider

:setup_anthropic
echo.
echo === ANTHROPIC CLAUDE ===
call :ask_key "Anthropic"
if errorlevel 1 goto setup_provider
call :verify_key anthropic "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_anthropic
) else (
    echo   [OK] Key verified!
)
call :pick_model "CLAUDE MODELS" "claude-4-sonnet" claude-4-sonnet claude-4-opus claude-3.7-sonnet claude-3.5-sonnet claude-3.5-haiku claude-3-opus claude-3-haiku
call :finalize_native anthropic Anthropic
(
    echo AI_PROVIDER=anthropic
    echo ANTHROPIC_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_openai
echo.
echo === OPENAI ===
call :ask_key "OpenAI"
if errorlevel 1 goto setup_provider
call :verify_key openai "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_openai
) else (
    echo   [OK] Key verified!
)
call :pick_model "OPENAI MODELS" "gpt-4.1" gpt-4.1 gpt-4.1-mini gpt-4.1-nano gpt-4.5-preview gpt-4o gpt-4o-mini o3 o3-mini o4-mini o1 o1-pro o1-mini
call :finalize_native openai "OpenAI"
(
    echo AI_PROVIDER=openai
    echo OPENAI_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_gemini
echo.
echo === GOOGLE GEMINI ===
call :ask_key "Gemini"
if errorlevel 1 goto setup_provider
call :verify_key gemini "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_gemini
) else (
    echo   [OK] Key verified!
)
call :pick_model "GEMINI MODELS" "gemini-2.5" gemini-2.5 gemini-2.5-flash gemini-2.0-flash gemini-2.0-flash-lite
call :finalize_native gemini "Google"
(
    echo AI_PROVIDER=gemini
    echo GEMINI_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_openrouter
echo.
echo === OPENROUTER ===
call :ask_key "OpenRouter"
if errorlevel 1 goto setup_provider
call :verify_key openrouter "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_openrouter
) else (
    echo   [OK] Key verified!
)
call :pick_model "OPENROUTER MODELS" "openrouter.deepseek-r1-free" openrouter.deepseek-r1-free openrouter.claude-3.7-sonnet openrouter.claude-3.5-sonnet openrouter.gpt-4.1 openrouter.gpt-4.1-mini openrouter.o3-mini openrouter.o4-mini openrouter.gemini-2.5 openrouter.gemini-2.5-flash openrouter.claude-3.5-haiku openrouter.claude-3-opus openrouter.gpt-4o openrouter.gpt-4o-mini
call :finalize_native openrouter "OpenRouter"
(
    echo AI_PROVIDER=openrouter
    echo OPENROUTER_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_groq
echo.
echo === GROQ ===
call :ask_key "Groq"
if errorlevel 1 goto setup_provider
call :verify_key groq "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_groq
) else (
    echo   [OK] Key verified!
)
call :pick_model "GROQ MODELS" "llama-3.3-70b-versatile" llama-3.3-70b-versatile meta-llama/llama-4-scout-17b-16e-instruct meta-llama/llama-4-maverick-17b-128e-instruct deepseek-r1-distill-llama-70b qwen-qwq
call :finalize_native groq "Groq"
(
    echo AI_PROVIDER=groq
    echo GROQ_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_xai
echo.
echo === XAI GROK ===
call :ask_key "xAI"
if errorlevel 1 goto setup_provider
call :verify_key xai "!USER_API_KEY!"
if errorlevel 1 (
    echo   [WARN] Could not verify the key (offline or invalid).
    set /p "SAVE_ANYWAY=  Continue anyway? (y/N): "
    if /i not "!SAVE_ANYWAY!"=="y" goto setup_xai
) else (
    echo   [OK] Key verified!
)
call :pick_model "XAI MODELS" "grok-3-beta" grok-3-beta grok-3-mini-beta grok-3-fast-beta grok-3-mini-fast-beta
call :finalize_native xai "xAI"
(
    echo AI_PROVIDER=xai
    echo XAI_API_KEY=!USER_API_KEY!
    echo OPENCODE_MODEL=!OPENCODE_MODEL!
    echo OPENCODE_CUSTOM_MODEL=!OPENCODE_CUSTOM_MODEL!
    echo OPENCODE_API_MODEL=!OPENCODE_API_MODEL!
    echo AI_DISPLAY_MODEL=!AI_DISPLAY_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_nvidia
echo.
echo === NVIDIA NIM ===
echo   Free API keys: https://build.nvidia.com
echo.
call :ask_key "NVIDIA"
if errorlevel 1 goto setup_provider
echo.
echo   --- NVIDIA NIM MODELS ---
echo    1) nvidia/nemotron-3-nano-omni-30b-a3b-reasoning  [default]
echo    2) nvidia/nemotron-3-ultra-550b-a55b
echo    3) minimaxai/minimax-m3.1-flash
echo    4) deepseek-ai/deepseek-v4.1-flash
echo    5) Manual model ID...
echo.
set "NV_SEL="
set /p "NV_SEL=  Choose a model (1-5) [Enter for 1]: "
if not defined NV_SEL set "NV_SEL=1"
set "LOCAL_MODEL="
if "!NV_SEL!"=="1" set "LOCAL_MODEL=nvidia/nemotron-3-nano-omni-30b-a3b-reasoning"
if "!NV_SEL!"=="2" set "LOCAL_MODEL=nvidia/nemotron-3-ultra-550b-a55b"
if "!NV_SEL!"=="3" set "LOCAL_MODEL=minimaxai/minimax-m3.1-flash"
if "!NV_SEL!"=="4" set "LOCAL_MODEL=deepseek-ai/deepseek-v4.1-flash"
if "!NV_SEL!"=="5" set /p "LOCAL_MODEL=  Enter the model ID: "
if not defined LOCAL_MODEL set "LOCAL_MODEL=nvidia/nemotron-3-nano-omni-30b-a3b-reasoning"
echo.
echo   [~] Verifying key with a test completion...
curl -s --connect-timeout 15 --max-time 90 -o "%TEMP%\opencode_nvidia_test.json" -w "%%{http_code}" -H "Authorization: Bearer !USER_API_KEY!" -H "Content-Type: application/json" -d "{\"model\":\"!LOCAL_MODEL!\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":8,\"stream\":false}" https://integrate.api.nvidia.com/v1/chat/completions > "%TEMP%\opencode_nvidia_code.txt" 2>nul
set /p NV_CODE=<"%TEMP%\opencode_nvidia_code.txt"
if not defined NV_CODE set "NV_CODE=000"
if "!NV_CODE!"=="200" (
    echo   [OK] Key verified!
) else if "!NV_CODE!"=="429" (
    echo   [WARN] Key accepted but rate-limited ^(HTTP 429^).
) else (
    if "!NV_CODE!"=="000" (
        echo   [ERROR] Could not reach NVIDIA ^(network/DNS/proxy/timeout^).
    ) else (
        echo   [ERROR] NVIDIA rejected the test request ^(HTTP !NV_CODE!^).
    )
    if exist "%TEMP%\opencode_nvidia_test.json" type "%TEMP%\opencode_nvidia_test.json"
    echo   Check the key at https://build.nvidia.com and that the model has access.
    set /p "NV_RETRY=  Try again? (Y/n): "
    if /i not "!NV_RETRY!"=="n" goto setup_nvidia
    echo   [WARN] Saving without a verified key.
)
del "%TEMP%\opencode_nvidia_test.json" "%TEMP%\opencode_nvidia_code.txt" >nul 2>&1
(
    echo AI_PROVIDER=local
    echo LOCAL_ENDPOINT=https://integrate.api.nvidia.com/v1
    echo LOCAL_API_KEY=!USER_API_KEY!
    echo LOCAL_MODEL=!LOCAL_MODEL!
    echo LOCAL_CAN_REASON=0
    echo LOCAL_CONTEXT_WINDOW=131072
    echo LOCAL_MAX_TOKENS=8192
    echo OPENCODE_MODEL=local.!LOCAL_MODEL!
    echo OPENCODE_CUSTOM_MODEL=0
    echo OPENCODE_API_MODEL=
    echo AI_DISPLAY_MODEL=NVIDIA !LOCAL_MODEL!
) > "%ENV_FILE%"
goto setup_done

:setup_local
echo.
echo === LOCAL / CUSTOM OPENAI-COMPATIBLE ===
echo   Works with Ollama, LM Studio, DeepSeek, NVIDIA NIM, and any
echo   server exposing GET /v1/models and POST /v1/chat/completions.
echo.
echo   Examples:
echo     LM Studio  http://localhost:1234/v1
echo     Ollama     http://localhost:11434/v1
echo     DeepSeek   https://api.deepseek.com/v1
echo     NVIDIA NIM https://integrate.api.nvidia.com/v1
echo.
set "LOCAL_ENDPOINT="
set /p "LOCAL_ENDPOINT=  Base URL [http://localhost:1234/v1]: "
if not defined LOCAL_ENDPOINT set "LOCAL_ENDPOINT=http://localhost:1234/v1"
if "!LOCAL_ENDPOINT:~-1!"=="/" set "LOCAL_ENDPOINT=!LOCAL_ENDPOINT:~0,-1!"
set "LOCAL_API_KEY="
set /p "LOCAL_API_KEY=  API key (Enter for none/local): "
if not defined LOCAL_API_KEY set "LOCAL_API_KEY=dummy"

echo   [~] Fetching models from !LOCAL_ENDPOINT!/models...
set /a LM_COUNT=0
for /f "usebackq delims=" %%M in (`powershell -NoProfile -Command "try { (Invoke-RestMethod -Uri '!LOCAL_ENDPOINT!/models' -Headers @{Authorization='Bearer !LOCAL_API_KEY!'} -TimeoutSec 10).data | ForEach-Object { $_.id } } catch { }"`) do (
    set /a LM_COUNT+=1
    set "LM_MODEL_!LM_COUNT!=%%M"
    echo   !LM_COUNT!^) %%M
)

if !LM_COUNT! EQU 0 (
    echo   [WARN] No models returned. Is the server running?
    set /p "LOCAL_MODEL=  Enter the model ID manually (or leave empty to retry): "
    if not defined LOCAL_MODEL goto setup_local
) else (
    set /a LM_MANUAL=LM_COUNT+1
    echo   !LM_MANUAL!^) Manual model ID...
    echo.
    set "LM_SEL="
    set /p "LM_SEL=  Choose a model (1-!LM_MANUAL!) [Enter for 1]: "
    if not defined LM_SEL set "LM_SEL=1"
    if "!LM_SEL!"=="!LM_MANUAL!" (
        set /p "LOCAL_MODEL=  Enter the model ID: "
    ) else (
        call set "LOCAL_MODEL=%%LM_MODEL_!LM_SEL!%%"
    )
    if not defined LOCAL_MODEL set "LOCAL_MODEL=!LM_MODEL_1!"
)
if not defined LOCAL_MODEL goto setup_local

(
    echo AI_PROVIDER=local
    echo LOCAL_ENDPOINT=!LOCAL_ENDPOINT!
    echo LOCAL_API_KEY=!LOCAL_API_KEY!
    echo LOCAL_MODEL=!LOCAL_MODEL!
    echo OPENCODE_MODEL=local.!LOCAL_MODEL!
    echo OPENCODE_CUSTOM_MODEL=0
    echo OPENCODE_API_MODEL=
    echo AI_DISPLAY_MODEL=!LOCAL_MODEL! ^(local^)
) > "%ENV_FILE%"
goto setup_done

:setup_done
echo.
echo   [OK] Settings saved to %ENV_FILE%
if "%SETUP_ONLY%"=="1" (
    echo.
    pause
    exit /b 0
)
goto main_ready

rem ============================================================
rem  Helpers
rem ============================================================
:ask_key
set "USER_API_KEY="
set /p "USER_API_KEY=  Enter your %~1 API key: "
if not defined USER_API_KEY (
    echo   [ERROR] Key cannot be empty!
    exit /b 1
)
set "USER_API_KEY=%USER_API_KEY: =%"
echo   Key: ********
exit /b 0

:verify_key
if /i "%~1"=="anthropic" goto vk_anthropic
if /i "%~1"=="openai" goto vk_openai
if /i "%~1"=="gemini" goto vk_gemini
if /i "%~1"=="openrouter" goto vk_openrouter
if /i "%~1"=="groq" goto vk_groq
if /i "%~1"=="xai" goto vk_xai
exit /b 0
:vk_anthropic
curl -sf --max-time 15 -H "x-api-key: %~2" -H "anthropic-version: 2023-06-01" https://api.anthropic.com/v1/models >nul 2>&1
exit /b %ERRORLEVEL%
:vk_openai
curl -sf --max-time 15 -H "Authorization: Bearer %~2" https://api.openai.com/v1/models >nul 2>&1
exit /b %ERRORLEVEL%
:vk_gemini
curl -sf --max-time 15 "https://generativelanguage.googleapis.com/v1beta/models?key=%~2" >nul 2>&1
exit /b %ERRORLEVEL%
:vk_openrouter
curl -sf --max-time 15 -H "Authorization: Bearer %~2" https://openrouter.ai/api/v1/auth/key >nul 2>&1
exit /b %ERRORLEVEL%
:vk_groq
curl -sf --max-time 15 -H "Authorization: Bearer %~2" https://api.groq.com/openai/v1/models >nul 2>&1
exit /b %ERRORLEVEL%
:vk_xai
curl -sf --max-time 15 -H "Authorization: Bearer %~2" https://api.x.ai/v1/models >nul 2>&1
exit /b %ERRORLEVEL%

:pick_model
setlocal EnableDelayedExpansion
set "PM_TITLE=%~1"
set "PM_DEFAULT=%~2"
shift
shift
set /a PM_IDX=1
:pm_list_loop
if "%~1"=="" goto pm_ask
set "PM_MODEL_!PM_IDX!=%~1"
if /i "%~1"=="!PM_DEFAULT!" (
    echo   !PM_IDX!^) %~1  [default]
) else (
    echo   !PM_IDX!^) %~1
)
set /a PM_IDX+=1
shift
goto pm_list_loop
:pm_ask
echo   !PM_IDX!^) Manual API model ID...
echo.
set "PM_SEL="
set /p "PM_SEL=  Choose a model (1-!PM_IDX!) [Enter for default]: "
if not defined PM_SEL set "PM_SEL=1"
if "!PM_SEL!"=="!PM_IDX!" goto pm_custom
set "PM_CUSTOM=0"
call set "PM_SELECTED=%%PM_MODEL_!PM_SEL!%%"
if not defined PM_SELECTED set "PM_SELECTED=!PM_DEFAULT!"
goto pm_finish
:pm_custom
set "PM_CUSTOM=1"
set /p "PM_SELECTED=  Enter the API model ID: "
if not defined PM_SELECTED (
    set "PM_CUSTOM=0"
    set "PM_SELECTED=!PM_DEFAULT!"
)
:pm_finish
endlocal & set "SELECTED_MODEL=%PM_SELECTED%" & set "SELECTED_MODEL_IS_CUSTOM=%PM_CUSTOM%"
exit /b 0

:finalize_native
if "%SELECTED_MODEL_IS_CUSTOM%"=="1" goto fn_custom
set "OPENCODE_CUSTOM_MODEL=0"
set "OPENCODE_API_MODEL="
set "OPENCODE_MODEL=%SELECTED_MODEL%"
set "AI_DISPLAY_MODEL=%~2 %SELECTED_MODEL%"
exit /b 0
:fn_custom
set "OPENCODE_CUSTOM_MODEL=1"
set "OPENCODE_API_MODEL=%SELECTED_MODEL%"
set "OPENCODE_MODEL=%~1.%SELECTED_MODEL%"
set "AI_DISPLAY_MODEL=%~2 %SELECTED_MODEL% (custom)"
exit /b 0

:render_config
set "OC_DATA_JSON=!OC_DATA_DIR:\=\\!"
set "KEY="
set "EXTRA="
set "AGENT_EXTRA="
if /i "!AI_PROVIDER!"=="anthropic" set "KEY=!ANTHROPIC_API_KEY!"
if /i "!AI_PROVIDER!"=="openai" set "KEY=!OPENAI_API_KEY!"
if /i "!AI_PROVIDER!"=="gemini" set "KEY=!GEMINI_API_KEY!"
if /i "!AI_PROVIDER!"=="openrouter" set "KEY=!OPENROUTER_API_KEY!"
if /i "!AI_PROVIDER!"=="groq" set "KEY=!GROQ_API_KEY!"
if /i "!AI_PROVIDER!"=="xai" set "KEY=!XAI_API_KEY!"
if /i "!AI_PROVIDER!"=="local" (
    set "KEY=!LOCAL_API_KEY!"
    set "AGENT_EXTRA=, "maxTokens": 8192"
)
if "!OPENCODE_CUSTOM_MODEL!"=="1" set "EXTRA=, "models": ["!OPENCODE_API_MODEL!"]"
(
    echo {
    echo   "data": {
    echo     "directory": "!OC_DATA_JSON!"
    echo   },
    echo   "providers": {
    echo     "!AI_PROVIDER!": { "apiKey": "!KEY!"!EXTRA! }
    echo   },
    echo   "agents": {
    echo     "coder": { "model": "!OPENCODE_MODEL!"!AGENT_EXTRA! },
    echo     "summarizer": { "model": "!OPENCODE_MODEL!"!AGENT_EXTRA! },
    echo     "task": { "model": "!OPENCODE_MODEL!"!AGENT_EXTRA! },
    echo     "title": { "model": "!OPENCODE_MODEL!" }
    echo   },
    echo   "autoCompact": true
    echo }
) > "%CONFIG_FILE%"
exit /b 0

rem ============================================================
rem  Main menu
rem ============================================================
:main_ready
call :render_config

echo.
echo  =========================================================
echo    OpenCode Portable  -  zero footprint on the host
echo  =========================================================
echo.
echo    Engine   : !OC_BIN!
echo    Provider : !AI_PROVIDER!
echo    Model    : !AI_DISPLAY_MODEL!
echo    Project  : !PROJECT_DIR!
echo    Data     : !OC_DATA_DIR!
echo  =========================================================
echo.

:menu_loop
echo   Select Action:
echo    1) Launch OpenCode            - TUI in !PROJECT_DIR! (auto in 10s)
echo    2) Launch with Debug logging
echo    3) Change Provider / Model / Key
echo    4) Show portable environment
echo    5) Exit
echo.
choice /c 12345 /n /t 10 /d 1 /m "  Select action (1-5): "
if errorlevel 5 exit /b 0
if errorlevel 4 goto show_env
if errorlevel 3 goto setup_provider
if errorlevel 2 goto launch_debug
goto launch_normal

:show_env
echo.
echo   ROOT_DIR        : %ROOT_DIR%
echo   ENGINE          : !OC_BIN!
echo   HOME            : !HOME!
echo   XDG_CONFIG_HOME : !XDG_CONFIG_HOME!
echo   XDG_DATA_HOME   : !XDG_DATA_HOME!
echo   XDG_CACHE_HOME  : !XDG_CACHE_HOME!
echo   CONFIG_FILE     : %CONFIG_FILE%
echo   DATA_DIR        : !OC_DATA_DIR!
echo.
goto menu_loop

:launch_debug
set "DEBUG_ARG=-d"
goto do_launch

:launch_normal
set "DEBUG_ARG="

:do_launch
echo.
echo   [~] Starting OpenCode... (Ctrl+C to quit)
echo.
cd /d "!PROJECT_DIR!"
"!OC_BIN!" !DEBUG_ARG!
set "STATUS=!ERRORLEVEL!"
echo.
echo   Session data: !OC_DATA_DIR!\opencode.db
echo   Exit code: !STATUS!
echo.
pause
exit /b !STATUS!
