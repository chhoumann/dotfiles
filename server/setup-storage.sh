#!/usr/bin/env bash
# Idempotent VDO + XFS data volume setup. Run as root after setup-system.sh:
#   sudo ~/dotfiles/server/setup-storage.sh
# Creates: vg0/vdopool (400G physical, dedup + LZ4) -> vg0/data (800G virtual, XFS) at /data
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run as root" >&2; exit 1; }

echo "== dm_vdo module"
echo dm_vdo > /etc/modules-load.d/dm-vdo.conf
modprobe dm_vdo

if ! lvs vg0/data >/dev/null 2>&1; then
    echo "== creating VDO pool + volume"
    # Threads sized for 8C/16T; dense 256M UDS index covers the whole device.
    # max_discard=256 (1MiB) keeps daily fstrim fast (default is one 4K block).
    lvcreate --type vdo --name data --size 400G --virtualsize 800G \
        --compression y --deduplication y \
        --vdosettings 'block_map_cache_size_mb=512 cpu_threads=4 hash_zone_threads=2 logical_threads=2 physical_threads=2 bio_threads=4 ack_threads=2 max_discard=256' \
        vg0/vdopool
    # -K: skip mkfs-time discard (fresh VDO volume is already zero; discard would crawl)
    mkfs.xfs -K /dev/vg0/data
else
    echo "== vg0/data already exists, skipping create"
fi

echo "== mount /data"
install -d /data
grep -q '^/dev/vg0/data' /etc/fstab || echo '/dev/vg0/data /data xfs noatime 0 0' >> /etc/fstab
mountpoint -q /data || mount /data
install -d -o christian -g christian /data/dev

echo "== status"
lvs -o lv_name,lv_size,data_percent vg0
xfs_info /data | head -3
echo "Reminder: docker data-root is /data/docker (daemon.json); restart docker if it started before this mount existed:"
echo "  systemctl restart docker"
