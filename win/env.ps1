$CONFIG_URL = "网址"
$PORT = 443
$USERNAME = "用户名"
$PASSWORD = "用户密码"
$KEY = "解密密钥"
$DURATION = "72" # in hours

$ARCH = $env:PROCESSOR_ARCHITECTURE.ToLowerInvariant()
$VERSION = "1.13.12"
$EXE_URL = "https://github.com/SagerNet/sing-box/releases/download/v$VERSION/sing-box-$VERSION-windows-$ARCH.zip"

$CONFIG = "config.json"
$EXE = "sing-box.exe"
$PROCESS = "sing-box"
