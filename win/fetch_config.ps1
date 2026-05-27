$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
. "$workDir\env.ps1"


$version = $VERSION
$agent = "windows"

$config_url = $CONFIG_URL
$port = if ($PORT) { $PORT } else { "443" }
$username = $USERNAME
$password = $PASSWORD
$key = $KEY

$duration = [int]$DURATION

foreach ($var in "version", "config_url", "port", "username", "password", "key", "duration") {
    if ([string]::IsNullOrWhiteSpace((Get-Variable $var).Value)) {
        throw "Required variable '$var' not set"
    }
}


$config = Join-Path $workDir "config.json"
if (Test-Path $config) {
    $lastModified = (Get-Item $config).LastWriteTime
    $ageSeconds = ((Get-Date) - $lastModified).TotalSeconds

    if ($ageSeconds -lt ($duration * 3600)) {
        Write-Host "Found valid config within validity period"
        exit 0
    }
}


$tmpConfig = Join-Path $workDir ("config.$([guid]::NewGuid()).json")

$authPair = "$username`:$password"
$bytes = [Text.Encoding]::ASCII.GetBytes($authPair)
$basicAuth = [Convert]::ToBase64String($bytes)

$params = @{
    agent  = $agent
    version = $version
    key    = $key
}
$query = ($params.GetEnumerator() | ForEach-Object {
    "$($_.Key)=$([uri]::EscapeDataString($_.Value))"
}) -join "&"
$uri = "https://${config_url}:$port/cfg?$query"


try {
    Write-Host "Downloading config from $config_url at port $port with agent $agent and version $version"
    Invoke-WebRequest `
        -Uri $uri `
        -Headers @{ Authorization = "Basic $basicAuth" } `
        -OutFile $tmpConfig `
        -TimeoutSec 20

    Move-Item -Force $tmpConfig $config
} finally {
    Remove-Item $tmpConfig -Force -ErrorAction SilentlyContinue
}
