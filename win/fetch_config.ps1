. "$workDir\env.ps1"

$url = $URL
$port = if ($PORT) { $PORT } else { "443" }
$username = $USERNAME
$password = $PASSWORD
$key = $KEY

foreach ($var in "url", "port", "username", "password", "key") {
    if ([string]::IsNullOrWhiteSpace((Get-Variable $var).Value)) {
        throw "Required variable '$var' not set"
    }
}


$tmpConfig = Join-Path $workDir ("config." + [guid]::NewGuid() + ".json")


$version = (& $exe version | Select-Object -First 1).Split()[-1]
$agent = "windows"

$pair = "$username`:$password"
$bytes = [Text.Encoding]::ASCII.GetBytes($pair)
$basicAuth = [Convert]::ToBase64String($bytes)

$uriBuilder = [System.UriBuilder]::new("https://${url}:$port/cfg")
$query = [System.Web.HttpUtility]::ParseQueryString("")
$query["agent"] = $agent
$query["version"] = $version
$query["key"] = $key
$uriBuilder.Query = $query.ToString()

Write-Host "Downloading config from $url at port $port with agent '$agent' and version '$version'"
Invoke-WebRequest `
    -Uri $uriBuilder.Uri `
    -Headers @{ Authorization = "Basic $basicAuth" } `
    -OutFile $tmpConfig `
    -TimeoutSec 20


Move-Item -Force $tmpConfig $config
