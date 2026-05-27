$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
Set-Location $workDir


$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if (-not $isAdmin) {
    Start-Process powershell `
        -Verb RunAs `
        -WindowStyle Minimized `
        -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-NoExit",
            "-File", "`"$PSCommandPath`""
        )
    exit
}


try {
    if (Get-Process "sing-box" -ErrorAction SilentlyContinue) {
        Write-Host "sing-box is already running"
        exit 0
    }

    $exe = Join-Path $workDir "sing-box.exe"
    $config = Join-Path $workDir "config.json"

    if (-not (Test-Path $exe)) {
        throw "sing-box.exe not found: $exe"
    }

    if (-not (Test-Path $config)) {
        throw "config.json not found: $config"
    }

    Write-Host "Starting sing-box as Administrator..."
    & $exe run -c $config

    Write-Host ""
    Write-Host "sing-box exited with code $LASTEXITCODE"
}
catch {
    Write-Host ""
    Write-Host "ERROR:"
    Write-Host $_
}


Write-Host ""
Read-Host "Press Enter to exit"