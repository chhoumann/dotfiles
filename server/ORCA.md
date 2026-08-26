# Orca remote runtime

`install-orca.sh` installs or upgrades the latest official `orca-ide` Debian
package, verifies its GitHub release digest and package metadata, creates the
data-backed profile and workspace mounts, and installs `orca-serve.service`.
The application remains managed by dpkg and its packaged headless CLI runs as
the unprivileged `christian` user.

The state directories `~/.config/orca` and `~/.config/Orca` are bind-mounted
from `/data/home/orca-config`. Orca's default `~/orca/workspaces` tree is
covered by a `/data/home/orca-workspaces` bind mount at `~/orca`.

Create the host-owned environment before enabling the service:

```text
# /etc/orca-serve.env (root:root, mode 0600)
ORCA_PORT=6768
ORCA_PAIRING_ADDRESS=<tailnet IP or hostname>
```

Then run:

```bash
sudo ~/dotfiles/server/install-orca.sh
sudo systemctl enable --now orca-serve
```

The ready record in the journal contains a secret pairing URL. Read it locally
and add it in the client under Settings -> Remote Orca Servers; never publish
or paste it into diagnostics.

Updates are deliberate: rerun `sudo ~/dotfiles/server/install-orca.sh`, restart
`orca-serve`, and verify that a paired client reconnects. Server and client
versions should remain close.
