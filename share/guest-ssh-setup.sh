#!/bin/bash
# Run INSIDE the VM (as your normal user) to make it reachable from the host
# over SSH with key auth and passwordless sudo:
#   sudo mount -t 9p -o trans=virtio,version=9p2000.L vmtools /media && /media/guest-ssh-setup.sh
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

sudo pacman -S --needed --noconfirm openssh
sudo systemctl enable --now sshd

# Open port 22 if a firewall is active.
if command -v ufw >/dev/null && sudo ufw status | grep -q 'Status: active'; then
    sudo ufw allow ssh
fi
if command -v firewall-cmd >/dev/null && sudo firewall-cmd --state >/dev/null 2>&1; then
    sudo firewall-cmd --permanent --add-service=ssh && sudo firewall-cmd --reload
fi

# Authorize the host's key(s), without duplicates.
install -d -m 700 ~/.ssh
touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys
while IFS= read -r key; do
    [[ -n "$key" ]] && ! grep -qxF "$key" ~/.ssh/authorized_keys && echo "$key" >> ~/.ssh/authorized_keys
done < <(cat "$here/host-keys.pub" 2>/dev/null)

# Test VM only: passwordless sudo so the host can drive it non-interactively.
echo "$USER ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/99-test-vm >/dev/null
sudo chmod 440 /etc/sudoers.d/99-test-vm

echo "Done. From the host: ssh -p 2222 $USER@localhost"
[[ -s "$here/host-keys.pub" ]] || echo "No host keys were shared; add yours from the host (see add-ssh-key.ps1 on Windows)."
