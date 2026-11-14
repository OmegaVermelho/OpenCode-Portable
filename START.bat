@echo off
setlocal EnableDelayedExpansion

title MEGA-CODE-4 Portable

rem ============================================================
rem MEGA-CODE-4 - Windows launcher
rem Redirects runtime env to data\folder and encrypts keys at rest.
rem ============================================================

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
echo   MEGA-CODE-4  -  AI PROVIDER SELECTION
echo =========================================================
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

:render_config
after

:main_ready
call :render_config

echo.
echo  =========================================================
echo    MEGA-CODE-4  -  zero footprint on the host
echo  =========================================================
echo.
echo    Engine   : !OC_BIN!
echo    Provider : !AI_PROVIDER!
echo    Model    : !AI_DISPLAY_MODEL!
echo    Project  : !PROJECT_DIR!
echo    Data     : !OC_DATA_DIR!
echo  =========================================================
echo.

goto menu_loop

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
