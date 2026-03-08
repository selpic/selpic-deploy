#Requires -RunAsAdministrator
param(
    [string]$InstallDir = "C:\SELPIC",
    [string]$ZipUrl = "https://github.com/selpic/selpic-deploy/releases/latest/download/selpic3.zip"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ── 헬퍼 ──
function Step($n, $total, $msg) {
    Write-Host ""
    Write-Host "     $n / $total" -ForegroundColor DarkGray -NoNewline
    Write-Host "  $msg" -ForegroundColor White
}
function Done($msg)  { Write-Host "             $([char]0x2714) $msg" -ForegroundColor DarkCyan }
function Skip($msg)  { Write-Host "             - $msg" -ForegroundColor DarkGray }
function Fail($msg)  { Write-Host "             $([char]0x2718) $msg" -ForegroundColor Red }

$configPath = Join-Path $InstallDir "config.ini"
$exePath = Join-Path $InstallDir "selpic_new.exe"

# 설치 확인
if (-not (Test-Path $exePath)) {
    Fail "$InstallDir 에 SELPIC 3.0이 설치되어 있지 않습니다."
    Write-Host "             install.bat을 먼저 실행하세요." -ForegroundColor DarkGray
    Write-Host ""
    exit 1
}

# ── 1. 프로세스 종료 ──
Step 1 4 "실행 중인 앱 종료"

$proc = Get-Process -Name "selpic_new" -ErrorAction SilentlyContinue
if ($proc) {
    $proc | Stop-Process -Force
    Start-Sleep -Seconds 2
    Done "selpic_new.exe 종료됨"
} else {
    Skip "실행 중이 아닙니다"
}

# ── 2. config.ini 백업 ──
Step 2 4 "설정 백업"

$backupPath = "$env:TEMP\selpic_config_backup.ini"
if (Test-Path $configPath) {
    Copy-Item $configPath $backupPath -Force
    Done "config.ini 백업 완료"
} else {
    Skip "config.ini 없음"
}

# ── 3. 파일 교체 ──
Step 3 4 "파일 업데이트"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($ZipUrl) {
    $zipPath = "$env:TEMP\selpic3_update.zip"

    # Google Drive 대용량 confirm 우회
    if ($ZipUrl -match "drive\.google\.com") {
        $fileId = if ($ZipUrl -match "id=([^&]+)") { $Matches[1] }
                  elseif ($ZipUrl -match "/d/([^/]+)") { $Matches[1] }
                  else { $ZipUrl }
        $resp = Invoke-WebRequest "https://drive.google.com/uc?export=download&id=$fileId" -SessionVariable gSession -UseBasicParsing
        $confirm = ([regex]'confirm=([0-9A-Za-z_]+)').Match($resp.Content).Groups[1].Value
        if ($confirm) {
            Invoke-WebRequest "https://drive.google.com/uc?export=download&confirm=$confirm&id=$fileId" -WebSession $gSession -OutFile $zipPath -UseBasicParsing
        } else {
            Invoke-WebRequest "https://drive.google.com/uc?export=download&id=$fileId" -OutFile $zipPath -UseBasicParsing
        }
    } else {
        Invoke-WebRequest $ZipUrl -OutFile $zipPath -UseBasicParsing
    }

    Expand-Archive -Path $zipPath -DestinationPath $InstallDir -Force
    Remove-Item $zipPath -ErrorAction SilentlyContinue
    Done "다운로드 완료"
}
else {
    $zipFile = Get-ChildItem "$scriptDir\*.zip" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($zipFile) {
        Expand-Archive -Path $zipFile.FullName -DestinationPath $InstallDir -Force
        Done "$($zipFile.Name) 해제 완료"
    }
    else {
        Copy-Item "$scriptDir\*" -Destination $InstallDir -Recurse -Force -Exclude "*.ps1","*.bat"
        Done "파일 복사 완료"
    }
}

# config.ini 복원
if (Test-Path $backupPath) {
    Copy-Item $backupPath $configPath -Force
    Remove-Item $backupPath -ErrorAction SilentlyContinue
    Done "config.ini 복원 완료"
}

# ── 4. 재실행 ──
Step 4 4 "앱 재실행"

Start-Process $exePath -WorkingDirectory $InstallDir
Done "SELPIC 3.0 실행됨"

# ── 완료 ──
# config에서 지점코드 읽기
$branch = ""
if (Test-Path $configPath) {
    $match = (Get-Content $configPath -Raw) | Select-String "Code=(.+)"
    if ($match) { $branch = $match.Matches.Groups[1].Value.Trim() }
}

Write-Host ""
Write-Host ""
Write-Host "     ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "       업데이트가 완료되었습니다." -ForegroundColor White
if ($branch) {
Write-Host ""
Write-Host "       지점코드    " -NoNewline -ForegroundColor DarkGray
Write-Host "$branch" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "     ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
