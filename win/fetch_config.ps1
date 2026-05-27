$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
. "$workDir\env.ps1"

$config_url = $CONFIG_URL
$port = if ($PORT) { $PORT } else { "443" }
$username = $USERNAME
$password = $PASSWORD
$key = $KEY
$version = $VERSION
$agent = "windows"

foreach ($var in "config_url", "port", "username", "password", "key", "version") {
    if ([string]::IsNullOrWhiteSpace((Get-Variable $var).Value)) {
        throw "Required variable '$var' not set"
    }
}


$config = Join-Path $workDir "config.json"
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