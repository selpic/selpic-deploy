#Requires -RunAsAdministrator
param(
    [Parameter(Mandatory=$true)][string]$BranchCode,
    [string]$InstallDir = "C:\SELPIC",
    [string]$ZipUrl = ""
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

# ── 2. 파일 설치 ──
Step 2 4 "파일 설치"

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

if ($ZipUrl) {
    $zipPath = "$env:TEMP\selpic3.zip"

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

# ── 3. 설정 ──
Step 3 4 "설정 적용"

$configPath = Join-Path $InstallDir "config.ini"
$exePath = Join-Path $InstallDir "selpic_new.exe"

if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw -Encoding UTF8
    $content = $content -replace "(?m)^Code=.*$", "Code=$BranchCode"
    Set-Content $configPath $content -NoNewline -Encoding UTF8
    Done "지점코드 $BranchCode 적용"
} else {
    @"
[Branch]
Code=$BranchCode
Name=
DeviceType=C

[Printer]
Type=Brother HL-L9430CDN series
Type2=
GhostScript=

[System]
PollInterval=5
RetryCount=3

[Payment]
PaymentCode=
TerminalCode=
"@ | Set-Content $configPath -Encoding UTF8
    Done "config.ini 생성 (지점코드 $BranchCode)"
}

# ── 4. 시스템 등록 + 실행 ──
Step 4 4 "시스템 등록"

# 자동실행
$runKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
Set-ItemProperty -Path $runKey -Name "SELPIC" -Value "`"$exePath`""
Done "부팅 시 자동실행"

# 바탕화면 바로가기
$WshShell = New-Object -ComObject WScript.Shell
$lnk = $WshShell.CreateShortcut((Join-Path ([Environment]::GetFolderPath("CommonDesktopDirectory")) "SELPIC.lnk"))
$lnk.TargetPath = $exePath
$lnk.WorkingDirectory = $InstallDir
$lnk.Description = "SELPIC 3.0"
$lnk.Save()
Done "바탕화면 바로가기"

# 방화벽
if (-not (Get-NetFirewallRule -DisplayName "SELPIC" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule -DisplayName "SELPIC" -Direction Inbound -Program $exePath -Action Allow -Profile Any | Out-Null
    Done "방화벽 예외"
}

# 실행
Start-Process $exePath -WorkingDirectory $InstallDir
Done "SELPIC 3.0 실행됨"

# ── 완료 ──
Write-Host ""
Write-Host ""
Write-Host "     ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
Write-Host "       설치가 완료되었습니다." -ForegroundColor White
Write-Host ""
Write-Host "       지점코드    " -NoNewline -ForegroundColor DarkGray
Write-Host "$BranchCode" -ForegroundColor Cyan
Write-Host "       설치경로    " -NoNewline -ForegroundColor DarkGray
Write-Host "$InstallDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "     ─────────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""
