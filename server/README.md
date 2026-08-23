# Dedicated dev server provisioning

Provisioning kit for a Hetzner dedicated server (Ubuntu 26.04) used as a dev
box. Storage: XFS on LVM VDO (inline dedup + LZ4 compression) on RAID1 NVMe.
Rule: never hand-edit system config on the box; edit here and re-run the
setup scripts.

## Build from bare metal

1. Boot the Hetzner rescue system.
2. Set `HOSTNAME` in `installimage.conf`, then `installimage -a -c
   installimage.conf` (the binary is at
   `/root/.oldroot/nfs/install/installimage` in non-interactive sessions).
   Reboot.
3. As root: create the user, install their SSH key, grant sudo.
4. As the user:
   ```
   git clone https://github.com/chhoumann/dotfiles.git ~/dotfiles
   sudo ~/dotfiles/server/setup-system.sh
   sudo ~/dotfiles/server/setup-storage.sh
   ```
5. Interactive finishers: `tailscale up`, `vncpasswd` (then restart the VNC
   units), `gh auth login`, agent CLI logins, and the dotbot link step.
6. Re-run both scripts any time; they are idempotent and are the
   drift-correction mechanism.

## Storage layout

- RAID1 across both NVMe drives (installimage), ESP + /boot + XFS root LV in
  vg0, rest of vg0 free.
- setup-storage.sh: VDO pool -> thin virtual XFS volume at /data, with VG
  headroom kept for emergency lvextend. Docker data-root lives on /data.
- Pool exhaustion is the failure mode: writes fail while df shows free space.
  vdo-pool-check.timer warns at 80% physical. Daily fstrim is what returns
  freed blocks to the pool; do not disable it.

## Notes

- needrestart is configured to NOT auto-restart docker/containerd/tailscaled/
  VNC/dbus during unattended upgrades (a dbus restart drops all SSH
  sessions); reboot manually when /var/run/reboot-required appears.
- Netdata is installed via its official kickstart script (no longer packaged
  in Ubuntu) and bound to localhost.
- Known cosmetic: dm-vdo logs a `__GFP_RETRY_MAYFAIL` vmalloc warning on
  activation on kernel 7.0 (Launchpad #2163712). Ignore.
