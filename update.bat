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
echo       업데이트
echo     ─────────────────────────────────────────────
echo.
echo       기존 설정(지점코드, 프린터)은 유지됩니다.
echo       실행 중인 앱을 종료하고 파일을 교체합니다.
echo.
echo.
set /p CONFIRM=     계속 진행할까요? (Y/N)  ^>

if /i not "%CONFIRM%"=="Y" (
    echo.
    echo       업데이트가 취소되었습니다.
    echo.
    pause
    exit /b 0
)

echo.

:: ps1이 같은 폴더에 있으면 사용, 없으면 GitHub에서 다운로드
if exist "%~dp0update.ps1" (
    powershell -ExecutionPolicy Bypass -File "%~dp0update.ps1"
) else (
    powershell -ExecutionPolicy Bypass -Command "& { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ps = \"$env:TEMP\selpic_update.ps1\"; Invoke-WebRequest 'https://raw.githubusercontent.com/selpic/selpic-deploy/main/update.ps1' -OutFile $ps -UseBasicParsing; & $ps; Remove-Item $ps -ErrorAction SilentlyContinue }"
)

echo.
echo     아무 키나 누르면 닫힙니다.
pause >nul
