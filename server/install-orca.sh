#!/usr/bin/env bash
# Install or upgrade Orca from the latest official native Debian package.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
SERVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "== data-backed Orca profiles"
for profile in orca Orca; do
    source_dir="/data/home/orca-config/$profile"
    target_dir="/home/christian/.config/$profile"
    install -d -o christian -g christian -m 700 "$source_dir" "$target_dir"
    if ! mountpoint -q "$target_dir"; then
        if find "$target_dir" -mindepth 1 -print -quit | grep -q .; then
            echo "ERROR: $target_dir is non-empty and not mounted." >&2
            echo "Stop Orca, copy it to $source_dir, verify it, then rerun." >&2
            exit 1
        fi
        grep -q "^$source_dir $target_dir " /etc/fstab || \
            echo "$source_dir $target_dir none bind 0 0" >> /etc/fstab
        mount "$target_dir"
    fi
done

echo "== data-backed Orca workspaces"
workspace_source=/data/home/orca-workspaces
workspace_target=/home/christian/orca
install -d -o christian -g christian -m 700 "$workspace_source" "$workspace_target"
if ! mountpoint -q "$workspace_target"; then
    if find "$workspace_target" -mindepth 1 -print -quit | grep -q .; then
        echo "ERROR: $workspace_target is non-empty and not mounted." >&2
        echo "Stop Orca, copy it to $workspace_source, verify it, then rerun." >&2
        exit 1
    fi
    grep -q "^$workspace_source $workspace_target " /etc/fstab || \
        echo "$workspace_source $workspace_target none bind 0 0" >> /etc/fstab
    mount "$workspace_target"
fi

case "$(dpkg --print-architecture)" in
    amd64) asset_pattern='^orca-ide_[0-9.]+_amd64\.deb$' ;;
    arm64) asset_pattern='^orca-ide_[0-9.]+_arm64\.deb$' ;;
    *) echo "unsupported architecture: $(dpkg --print-architecture)" >&2; exit 1 ;;
esac

release_ref="${1:-latest}"
if [ "$release_ref" = latest ]; then
    release_url=https://api.github.com/repos/stablyai/orca/releases/latest
else
    release_url="https://api.github.com/repos/stablyai/orca/releases/tags/${release_ref}"
fi

release_json="$(curl -fsSL --retry 3 "$release_url")"
release_tag="$(jq -er '.tag_name' <<<"$release_json")"
asset_json="$(jq -ec --arg pattern "$asset_pattern" \
    '.assets[] | select(.name | test($pattern))' <<<"$release_json")"
asset_name="$(jq -er '.name' <<<"$asset_json")"
asset_url="$(jq -er '.browser_download_url' <<<"$asset_json")"
asset_digest="$(jq -er '.digest | select(startswith("sha256:"))' <<<"$asset_json")"

installed_version="$(dpkg-query -W -f='${Version}' orca-ide 2>/dev/null || true)"
if [ "$installed_version" = "${release_tag#v}" ]; then
    echo "Orca ${installed_version} is already installed"
else
    staging_dir="$(mktemp -d /tmp/orca-install.XXXXXX)"
    trap 'rm -rf -- "$staging_dir"' EXIT
    deb_path="$staging_dir/$asset_name"

    curl -fL --retry 3 "$asset_url" -o "$deb_path"
    printf '%s  %s\n' "${asset_digest#sha256:}" "$deb_path" | sha256sum -c -

    [ "$(dpkg-deb -f "$deb_path" Package)" = orca-ide ]
    [ "$(dpkg-deb -f "$deb_path" Version)" = "${release_tag#v}" ]
    [ "$(dpkg-deb -f "$deb_path" Architecture)" = "$(dpkg --print-architecture)" ]

    apt-get install -y "$deb_path"
fi
test -x /usr/bin/orca-ide

echo "== systemd service"
install -m 644 "$SERVER_DIR/systemd/orca-serve.service" \
    /etc/systemd/system/orca-serve.service
systemctl daemon-reload

echo "Installed Orca $(dpkg-query -W -f='${Version}' orca-ide)"
