#!/bin/bash
# Screenshot the guest's Plasma session to a file on the host.
#   scripts/vmshot.sh <out.png>
# spectacle started straight from SSH crashes; run it as a user unit so it
# gets the session's environment.
# Env: VM_USER (theupriser), VM_PORT (2222), VM_HOST (localhost), GUEST_UID (1000).
set -euo pipefail
. "$(dirname "$0")/common.sh"
out="${1:?usage: $0 <out.png>}"
{ printf 'uid=%q\n' "${GUEST_UID:-1000}"; cat << 'REMOTE'
export XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus
rm -f /tmp/vmshot.png
sleep 2
systemd-run --user --wait -q spectacle -b -n -f -o /tmp/vmshot.png
REMOTE
} | vm_ssh bash -s
scp -q -P "$VM_PORT" "$VM_USER@$VM_HOST:/tmp/vmshot.png" "$out"
echo "$out"
