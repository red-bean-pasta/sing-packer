#!/usr/bin/env bash
set -euo pipefail

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

Main(){
    SourceEnv

    arch=$(GetArch)
    kernel=$(GetKernel)
    version=${VERSION:-}
    exe_url=$(GetExeUrl "$version" "$kernel" "$arch")
    EnsureVarSet version exe_url

    executable="$work_dir/sing-box"
    EnsureExeExists

    config_url=${CONFIG_URL:-}
    port=${PORT:-443}
    username=${USERNAME:-}
    password=${PASSWORD:-}
    key=${KEY:-}
    duration=${DURATION:-}
    EnsureVarSet config_url port username password key duration

    config="$work_dir/config.json"
    EnsureConfig

    LaunchExe
}

SourceEnv(){
    local env; env="$work_dir/env"
    if [ -f "$env" ]; then
        set -a
        # shellcheck source=./env
        source "$env"
        set +a
    fi
}

EnsureVarSet(){
    local var; for var in "$@"; do
        if [ -z "${!var}" ]; then
            Log "Error: Required variable '$var' not set"
            exit 1
        fi
    done
}

EnsureExeExists(){
    ValidateElseDownloadExe

    if ! [[ -x "$executable" ]]; then
        echo "Executable missing or version mismatch: $executable" >&2
        exit 1
    fi
}

EnsureConfig(){
    if [[ ! -f "$config" ]]; then
        Log "Config file not found. Initializing..."
        DownloadConfig
        return 0
    fi
    if CheckConfigExpired "$config" "$duration"; then
        Log "Config file expired. Refreshing..."
        DownloadConfig
        return 0
    fi
    Log "Found valid config file"
    return 0
}

LaunchExe(){
    Log "Launching $executable with sudo privilege..."
    exec sudo "$executable" run -c "$config" -D "$work_dir"
}

ValidateElseDownloadExe(){
    if [[ -f "$executable" ]] && [[ $(GetExeVersion) == "$version" ]]; then
		Log "Found executable with matched version"
        return 
    fi

    Log "Executable not found"
	local temp_save; temp_save="$(mktemp "${work_dir}/tar.gz.XXXXXX")"
	{
		DownloadExe "$temp_save" &&
		ExtractExe "$temp_save" "$work_dir" true &&
		chmod +x "$executable"
	} || {
		rm -f "$temp_save"
		return 1
	}
}

GetExeVersion(){
    "$executable" version | awk 'NR==1 {print $NF}'
}

DownloadExe(){
    Log "Downloading executable from $exe_url..."
    local dest=$1
    curl -L \
        --connect-timeout 10 \
        --retry 3 \
        --fail \
        --show-error \
        -o "$dest" \
        "$exe_url"
}

ExtractExe() {
	Log "Extracting downloaded archive..."

    local from=$1
    local dest=$2
	local delete=$3
    if tar -tzf "$from" | grep '/' >/dev/null; then
        tar -xzf "$from" -C "$dest" --strip-components=1
    else
        tar -xzf "$from" -C "$dest"
    fi

	if $delete; then
		rm -f "$from"
	fi
}

CheckConfigExpired(){
    local now; now=$(date +%s)
    local mtime; mtime=$(stat -c %Y "$1")
    local age; age=$(( now - mtime ))
    (( age > $2 * 3600 ))
}

DownloadConfig(){
    local tmp; tmp="$(mktemp "${work_dir}/config.json.XXXXXX")"
    local agent; agent=$(GetAgent)
    Log "Curling config from $config_url at port $port with agent as '$agent' and version '$version'..."
    curl \
        --connect-timeout 10 \
        --max-time 20 \
        --silent \
        --fail --show-error \
        -u "$username:$password" \
        --get "https://$config_url:$port/cfg" \
        --data-urlencode "agent=$agent" \
        --data-urlencode "version=$version" \
        --data-urlencode "key=$key" \
        -o "$tmp" || {
			rm -f "$tmp"
			return 1
		}

    mv "$tmp" "$config"
}

GetArch(){
    local arch; arch="$(uname -m)"
    case "$arch" in
		i386|i486|i586|i686)
			echo "386" ;;
        x86_64)
            echo "amd64" ;;
		aarch64)
			echo "arm64" ;;
        *)
            echo "$arch" ;;
    esac
}

GetKernel(){
    local os; os="$(uname -s)"
    case "$os" in
		Linux*)
			echo "linux" ;;
		Darwin*)
			echo "darwin" ;;
		*)
			echo "$os" ;;
	esac
}

GetAgent(){
    local os; os=${kernel:-$(GetKernel)}
    case "$os" in
    linux*)
        echo "linux"
        ;;
    darwin*)
        echo "macos"
        ;;
    *)
        Log "Unsupported OS: $os"
        return 1
        ;;
esac
}

Log(){
    echo "$1" >&2
}

Main