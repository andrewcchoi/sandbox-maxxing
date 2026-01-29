: << 'CMDBLOCK'
@echo off
REM ============================================================================
REM Cross-Platform Polyglot Hook Runner
REM ============================================================================
REM This polyglot script is valid in both Windows CMD and Unix bash.
REM
REM Technique adapted from the superpowers plugin for Claude Code:
REM   https://github.com/obra/superpowers
REM   docs/windows/polyglot-hooks.md
REM
REM On Windows: CMD executes batch commands, calls Git Bash for .sh scripts
REM On Unix: bash ignores batch via heredoc, executes shell commands directly
REM ============================================================================
REM Usage: run-hook.cmd <script-name.sh> [args...]
REM ============================================================================
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_NAME=%~1"
if "%SCRIPT_NAME%"=="" (
    echo run-hook.cmd: missing script name >&2
    exit /b 1
)
REM Find Git Bash
set "BASH_EXE="
if exist "%ProgramFiles%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles%\Git\bin\bash.exe"
if "%BASH_EXE%"=="" if exist "%ProgramFiles(x86)%\Git\bin\bash.exe" set "BASH_EXE=%ProgramFiles(x86)%\Git\bin\bash.exe"
if "%BASH_EXE%"=="" if exist "%LOCALAPPDATA%\Programs\Git\bin\bash.exe" set "BASH_EXE=%LOCALAPPDATA%\Programs\Git\bin\bash.exe"
if "%BASH_EXE%"=="" (
    echo Git Bash not found. Please install Git for Windows. >&2
    exit /b 1
)
"%BASH_EXE%" -l -c "cd \"$(cygpath -u \"%SCRIPT_DIR%\")\" && \"./%SCRIPT_NAME%\""
exit /b
CMDBLOCK

# ============================================================================
# Unix shell execution starts here
# ============================================================================
# Polyglot technique from superpowers plugin: https://github.com/obra/superpowers
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_NAME="$1"
if [ -z "$SCRIPT_NAME" ]; then
    echo "run-hook.cmd: missing script name" >&2
    exit 1
fi
shift
"${SCRIPT_DIR}/${SCRIPT_NAME}" "$@"
