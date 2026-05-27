$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
. "$workDir\env.ps1"

$version = $VERSION
$exe_url = $EXE_URL
$exe = Join-Path $workDir "$EXE"

foreach ($var in "version", "exe_url") {
    if ([string]::IsNullOrWhiteSpace((Get-Variable $var).Value)) {
        throw "Required variable '$var' not set"
    }
}


function Test-Exist {
    Test-Path $exe -PathType Leaf
}

function Match-Version {
    try {
        $line = & $exe version 2>$null | Select-Object -First 1
        if ($LASTEXITCODE -ne 0) {
            return $false
        }
        if ([string]::IsNullOrWhiteSpace($line)) {
            return $false
        }
        $current_version = $line.Split()[-1]
        return  ($current_version -eq $version)
    } catch {
        return  $false
    }
}

if ((Test-Exist) -and (Match-Version)) {
    Write-Host "Found valid executable"
    exit 0
}


$tmpZip = $tmpZip = Join-Path $env:TEMP ("$([guid]::NewGuid()).zip")
$tmpDir = Join-Path $env:TEMP (([guid]::NewGuid()).ToString())

try {
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    Write-Host "Downloading executable archive from $exe_url..."
    $downloaded = $false
    for ($i = 1; $i -le 3; $i++) {
        try {
            Invoke-WebRequest `
                -Uri $exe_url `
                -OutFile $tmpZip `
                -UseBasicParsing `
                -ErrorAction Stop

            $downloaded = $true
            break
        } catch {
            if ($i -lt 3) {
                Start-Sleep -Seconds 5
            }
        }
    }
    if (-not $downloaded) {
        throw "Download failed."
    }

    Write-Host "Unarchiving downloaded $tmpZip..."
    Expand-Archive -Path $tmpZip -DestinationPath $tmpDir -Force
    $items = @(Get-ChildItem $tmpDir -Force)
    if ($items.Count -eq 0) {
        throw "Downloaded archive is empty"
    }
    $src = if ($items[0].PSIsContainer) {
        $items[0].FullName
    } else {
        $tmpDir
    }

    Copy-Item `
        -Path (Join-Path $src "*") `
        -Destination $workDir `
        -Recurse `
        -Force

    if (-not (Test-Exist)) {
        throw "'$exe' was not found after install."
    }
    if (-not (Match-Version)) {
        throw "'$exe' does not match version '$version' after install."
    }
}
finally {
    Remove-Item $tmpZip -Force -ErrorAction SilentlyContinue
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}