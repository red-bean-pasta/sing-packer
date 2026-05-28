#! /usr/bin/env bash
set -euo pipefail

work_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

Main(){
    CheckDependency notify-send pkexec konsole || exit 1
    Launch
}

CheckDependency(){
    local ok=true
    local i; for i in "$@"; do
        if ! command -v "$i" >/dev/null; then
            Notify "Missing Dependency" "Cannot locate $i. Please check if it's installed"
            ok=false
        fi
    done
    $ok
}

Launch() {
    local script="$work_dir/launch.sh"
    # Wayland and Plasma6 doesn't allow minimized startup
    # shellcheck disable=SC2016
    konsole --workdir "$work_dir" -e bash -c '
        bash "$1"
        echo
        read -p "Press Enter to close..."
    ' _ "$script"
}

Log(){
    echo "$@" >&2
}

Notify(){
    local title=$1
    local body="${*:2}"
    Log "$title: $body"
    notify-send "$title" "$body"
}

Main