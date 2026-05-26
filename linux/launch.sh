#!/usr/bin/env bash
set -euo pipefail

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

env="$work_dir/.env"
if [ -f "$env" ]; then
    set -a
    # shellcheck source=./.env
    source "$env"
    set +a
fi


url=${URL:-}
port=${PORT:-443}

username=${USERNAME:-}
password=${PASSWORD:-}

key=${KEY:-}


for var in url port username password key; do
    if [ -z "${!var}" ]; then
        echo "Error: Required variable '$var' not set" >&2
        exit 1
    fi
done


executable="$work_dir/sing-box"
if ! [[ -x "$executable" ]]; then
    echo "Executable not found or not executable: $executable" >&2
    exit 1
fi


config="$work_dir/config.json"
tmp_config="$(mktemp "$work_dir/config.XXXXXX.json")"
trap 'rm -f "$tmp_config"' EXIT


version=$(exec "$executable" version | awk 'NR==1 {print $NF}')
case "$(uname -s)" in
    Linux*)
        agent="linux"
        ;;
    Darwin*)
        agent="macos"
        ;;
    *)
        echo "Unsupported OS: $(uname -s)" >&2
        exit 1
        ;;
esac

echo "Curling config from $url at port $port with agent as 'linux' and version '$version'" >&2
curl \
    --connect-timeout 10 \
    --max-time 20 \
    --silent \
    --fail --show-error \
    -u "$username:$password" \
    --get "https://$url:$port/cfg" \
    --data-urlencode "agent=$agent" \
    --data-urlencode "version=$version" \
    --data-urlencode "key=$key" \
    -o "$tmp_config"


mv "$tmp_config" "$config"
trap - EXIT


exec sudo "$executable" run -c "$config"