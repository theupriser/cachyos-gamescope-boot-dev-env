# cachyos-gamescope-boot dev environment

A QEMU/KVM test VM running CachyOS (KDE Plasma 6) for developing and testing
[cachyos-gamescope-boot](https://github.com/theupriser/cachyos-gamescope-boot),
plus helper scripts and a Claude Code skill that documents the test workflow.

Only scripts and docs live here. The ISO, disk image, UEFI variable stores,
logs and screenshots are generated locally. `.gitignore` is an allowlist: it
ignores everything and un-ignores only the tracked files, so add any new
tracked file to it explicitly.

## Requirements

- Linux host with KVM, `qemu-system-x86_64` (GTK/OpenGL display, virtfs/9p) and `qemu-img`
  (Ubuntu: `sudo apt install qemu-system-x86 qemu-utils ovmf`).
- OVMF firmware at `/usr/share/OVMF/OVMF_CODE_4M.fd` and `OVMF_VARS_4M.fd`.
- `curl` and `sha256sum` for `get-iso.sh`.
- Optional: an NVIDIA dGPU for `--nvidia` (PRIME offload of the virgl renderer).

### Windows

`run.ps1` and `get-iso.ps1` are Windows versions. They need
[QEMU for Windows](https://qemu.weilnetz.de/w64/) (or set `QEMU_DIR`) and the
"Windows Hypervisor Platform" feature (`-accel whpx`). Windows QEMU has no 9p
shares: copy the repo into the guest with `scp -P 2222 -r ...`, and authorize
your key with `.\add-ssh-key.ps1 -User <vm-user>`.

## Quick start

```bash
./get-iso.sh        # download and verify the latest CachyOS desktop ISO
./run.sh install    # first run creates disk.qcow2 (60G) and vars.fd, boots the ISO
```

Install CachyOS with the **KDE Plasma** desktop and **plasma-login-manager**
as login manager. Power off and snapshot (only while the VM is off):

```bash
qemu-img snapshot -c clean disk.qcow2 && cp vars.fd vars.clean.fd
```

Boot the installed system (`./run.sh`) and, in the guest, enable SSH with key
auth and passwordless sudo through the read-only `vmtools` share:

```bash
sudo mount -t 9p -o trans=virtio,version=9p2000.L vmtools /media && /media/guest-ssh-setup.sh
```

Power off and snapshot again:

```bash
qemu-img snapshot -c ssh-ready disk.qcow2 && cp vars.fd vars.ssh-ready.fd
```

Connect with `ssh -p 2222 <user>@localhost`. The project repo is shared
read-write as 9p tag `repo`; in the guest:
`sudo mount -t 9p -o trans=virtio,version=9p2000.L repo /mnt`.

### run.sh options

```
[REPO=/path/to/cachyos-gamescope-boot] ./run.sh [install] [--nvidia] [--vulkan] [--fremont]
```

- `install`: boot the installer ISO
- `--nvidia`: render the guest's virtio-gpu (virgl) on the host NVIDIA dGPU
- `--vulkan`: expose Vulkan to the guest (venus; unstable)
- `--fremont`: fake the Valve Steam Machine (Fremont) DMI data via `-smbios`
- `REPO` defaults to `$HOME/projects/cachyos-gamescope-boot`

## Helper scripts

- `scripts/vmrun.sh '<menu input>'`: run the wizard in the guest's Plasma session with scripted input
- `scripts/vmstate.sh`: print the state of every wizard component
- `scripts/cmp.sh [save]`: save / diff the guest's KDE configs against a baseline

They use `VM_USER` (default `theupriser`), `VM_PORT` (`2222`) and `VM_HOST` (`localhost`).

## Claude Code skill

The full test workflow is documented in
[`.claude/skills/cachyos-vm-testing/SKILL.md`](.claude/skills/cachyos-vm-testing/SKILL.md);
Claude Code picks it up when run from this repo.
