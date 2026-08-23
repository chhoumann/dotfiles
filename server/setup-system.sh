#!/usr/bin/env bash
# Idempotent system provisioning for the agents box. Run as root:
#   sudo ~/dotfiles/server/setup-system.sh
set -euo pipefail

SERVER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"

echo "== timezone & locale"
timedatectl set-timezone Europe/Copenhagen
locale-gen en_US.UTF-8 >/dev/null
update-locale LANG=en_US.UTF-8

echo "== third-party apt repos"
install -d -m 755 /etc/apt/keyrings
add_repo() { # name key_url repo_line
    local key="/etc/apt/keyrings/$1.gpg"
    [ -f "$key" ] || curl -fsSL "$2" | gpg --dearmor -o "$key"
    echo "$3" > "/etc/apt/sources.list.d/$1.list"
}
add_repo nodesource "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key" \
    "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main"
add_repo tailscale "https://pkgs.tailscale.com/stable/ubuntu/${CODENAME}.noarmor.gpg" \
    "deb [signed-by=/etc/apt/keyrings/tailscale.gpg] https://pkgs.tailscale.com/stable/ubuntu ${CODENAME} main"
add_repo github-cli "https://cli.github.com/packages/githubcli-archive-keyring.gpg" \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/github-cli.gpg] https://cli.github.com/packages stable main"
add_repo 1password "https://downloads.1password.com/linux/keys/1password.asc" \
    "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/1password.gpg] https://downloads.1password.com/linux/debian/${ARCH} stable main"

echo "== packages"
apt-get update -qq
grep -vE '^\s*(#|$)' "$SERVER_DIR/packages.txt" | xargs apt-get install -y -qq

echo "== containerd image store on /data (docker data-root does not cover it)"
install -d /etc/containerd /data/containerd 2>/dev/null || true
[ -f /etc/containerd/config.toml ] || printf 'version = 2\nroot = "/data/containerd"\n' > /etc/containerd/config.toml

echo "== journal: persistent, capped"
install -d /etc/systemd/journald.conf.d
printf '[Journal]\nStorage=persistent\nSystemMaxUse=1G\n' > /etc/systemd/journald.conf.d/persistent.conf

echo "== heavy home dirs live on /data (root LV is small)"
install -d -o christian -g christian /data/home
for d in Developer .cache; do
    tgt="/data/home/${d#.}"; [ "$d" = ".cache" ] && tgt=/data/home/dot-cache
    install -d -o christian -g christian "$tgt" "/home/christian/$d"
    grep -q "$tgt " /etc/fstab || echo "$tgt /home/christian/$d none bind 0 0" >> /etc/fstab
    mountpoint -q "/home/christian/$d" || mount "/home/christian/$d" 2>/dev/null || true
done

echo "== system config files"
install -m 644 "$SERVER_DIR/etc/sysctl.d/99-agentbox.conf" /etc/sysctl.d/
install -m 644 "$SERVER_DIR/etc/zram-generator.conf" /etc/systemd/zram-generator.conf
install -d /etc/needrestart/conf.d
install -m 644 "$SERVER_DIR/etc/needrestart/agentbox.conf" /etc/needrestart/conf.d/
install -d /etc/docker
install -m 644 "$SERVER_DIR/etc/docker/daemon.json" /etc/docker/daemon.json
install -m 644 "$SERVER_DIR/etc/ssh/99-hardening.conf" /etc/ssh/sshd_config.d/
sysctl --system >/dev/null

echo "== systemd-oomd targets user slices"
install -d /etc/systemd/system/user@.service.d
cat > /etc/systemd/system/user@.service.d/oomd.conf <<'EOF'
[Service]
ManagedOOMMemoryPressure=kill
ManagedOOMMemoryPressureLimit=80%
EOF

echo "== file descriptor limits"
install -d /etc/systemd/system.conf.d /etc/systemd/user.conf.d
printf '[Manager]\nDefaultLimitNOFILE=8192:1048576\n' > /etc/systemd/system.conf.d/limits.conf
printf '[Manager]\nDefaultLimitNOFILE=8192:1048576\n' > /etc/systemd/user.conf.d/limits.conf

echo "== tailscale UDP offload on boot"
install -d /etc/networkd-dispatcher/routable.d
cat > /etc/networkd-dispatcher/routable.d/50-tailscale <<'EOF'
#!/bin/sh
NETDEV=$(ip -o route get 8.8.8.8 | cut -f5 -d' ')
ethtool -K "$NETDEV" rx-udp-gro-forwarding on rx-gro-list off || true
EOF
chmod 755 /etc/networkd-dispatcher/routable.d/50-tailscale

echo "== 8G disk swapfile as zram backstop (pri=-2)"
if [ ! -f /swapfile ]; then
    fallocate -l 8G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null
fi
grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw,pri=-2 0 0' >> /etc/fstab
swapon /swapfile 2>/dev/null || true

echo "== custom systemd units"
install -m 644 "$SERVER_DIR"/systemd/*.service "$SERVER_DIR"/systemd/*.timer /etc/systemd/system/
install -m 755 "$SERVER_DIR/vdo-pool-check" /usr/local/bin/vdo-pool-check
systemctl daemon-reload

echo "== vnc xstartup"
install -d -o christian -g christian -m 700 /home/christian/.vnc
install -o christian -g christian -m 755 "$SERVER_DIR/vnc-xstartup" /home/christian/.vnc/xstartup

echo "== firewall (tailnet + ssh only)"
ufw default deny incoming >/dev/null
ufw default allow outgoing >/dev/null
ufw allow in on tailscale0 >/dev/null
ufw allow 22/tcp >/dev/null
ufw allow 41641/udp >/dev/null
# Containers must not reach the tailnet: 100.64/10 is CGNAT space, which
# container network lockdowns that only cover RFC1918 miss. DOCKER-USER is
# the chain Docker consults before its own forward rules.
iptables -C DOCKER-USER -d 100.64.0.0/10 -j DROP 2>/dev/null || iptables -I DOCKER-USER 1 -d 100.64.0.0/10 -j DROP 2>/dev/null || true
if ! grep -q "DOCKER-USER" /etc/ufw/after.rules; then
    cat >> /etc/ufw/after.rules <<'EOF'

*filter
:DOCKER-USER - [0:0]
-A DOCKER-USER -d 100.64.0.0/10 -j DROP
-A DOCKER-USER -j RETURN
COMMIT
EOF
fi
ufw --force enable >/dev/null

echo "== docker group for christian"
usermod -aG docker christian

echo "== quiet ubuntu pro / motd ads"
command -v pro >/dev/null && pro config set apt_news=false 2>/dev/null || true
touch /var/lib/update-notifier/hide-esm-in-motd
[ -f /etc/update-motd.d/50-motd-news ] && chmod -x /etc/update-motd.d/50-motd-news

echo "== enable services (fstrim daily: VDO reclaims space only via trim)"
install -d /etc/systemd/system/fstrim.timer.d
printf '[Timer]\nOnCalendar=\nOnCalendar=daily\n' > /etc/systemd/system/fstrim.timer.d/daily.conf
systemctl daemon-reload
systemctl enable --now fstrim.timer systemd-oomd docker tailscaled
systemctl enable --now vncserver@1 novnc vdo-pool-check.timer || true

cat <<'EOF'
Done. Manual finishers (interactive):
  sudo tailscale up
  vncpasswd            (then: systemctl restart vncserver@1 novnc)
  gh auth login
  claude login / codex login --device-auth
EOF
