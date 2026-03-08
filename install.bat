@echo off
chcp 65001 >nul 2>&1
title SELPIC 3.0
color 0F
cls

echo.
echo.
echo     ███████╗███████╗██╗     ██████╗ ██╗ ██████╗
echo     ██╔════╝██╔════╝██║     ██╔══██╗██║██╔════╝
echo     ███████╗█████╗  ██║     ██████╔╝██║██║
echo     ╚════██║██╔══╝  ██║     ██╔═══╝ ██║██║
echo     ███████║███████╗███████╗██║     ██║╚██████╗
echo     ╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝ ╚═════╝  3.0
echo.
echo     ─────────────────────────────────────────────
echo       신규 설치
echo     ─────────────────────────────────────────────
echo.
echo.

set /p BRANCH_CODE=     지점코드를 입력하세요  ^>

if "%BRANCH_CODE%"=="" (
    echo.
    echo       지점코드가 입력되지 않았습니다.
    echo.
    pause
    exit /b 1
)

echo.
echo     ─────────────────────────────────────────────
echo       지점코드    %BRANCH_CODE%
echo       설치경로    C:\SELPIC
echo     ─────────────────────────────────────────────
echo.
echo.
set /p CONFIRM=     계속 진행할까요? (Y/N)  ^>

if /i not "%CONFIRM%"=="Y" (
    echo.
    echo       설치가 취소되었습니다.
    echo.
    pause
    exit /b 0
)

echo.
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1" -BranchCode "%BRANCH_CODE%"

echo.
echo     아무 키나 누르면 닫힙니다.
pause >nul
