#!/bin/bash
# Like vmrun.sh, but run the wizard in a visible Konsole window inside the
# guest's Plasma session, so someone at the QEMU window can follow along.
# Waits for the wizard to finish, then prints its log. The window stays open.
#   scripts/vmwatch.sh '<menu input>' ["label shown in the window"]
# Env: VM_USER (theupriser), VM_PORT (2222), VM_HOST (localhost),
#      GUEST_REPO (/mnt), GUEST_UID (1000), WAIT (seconds, default 1800).
set -euo pipefail
. "$(dirname "$0")/common.sh"
input="${1:?usage: $0 '<menu input>' [label]}"
label="${2:-Running the wizard}"
# The guest login shell is fish, so pass values in through the bash script itself.
{ printf 'input=%q label=%q repo=%q uid=%q wait=%q\n' "$input" "$label" "${GUEST_REPO:-/mnt}" \
    "${GUEST_UID:-1000}" "${WAIT:-1800}"; cat << 'REMOTE'
export XDG_RUNTIME_DIR=/run/user/$uid DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$uid/bus
[ -x "$repo/steamify.sh" ] || { echo "$repo/steamify.sh missing: mount the repo (lost after a reboot)" >&2; exit 1; }
rm -f /tmp/wizard.done
{
    echo '#!/bin/bash'
    printf 'echo %q; echo %q; sleep 3\n' ">>> $label" ">>> menu input: $input"
    # shellcheck disable=SC2016
    printf 'printf %q | %q 2>&1 | tee /tmp/wizard.log\n' "$input" "$repo/steamify.sh"
    echo 'touch /tmp/wizard.done'
} > /tmp/vmwatch-run.sh
chmod +x /tmp/vmwatch-run.sh
pkill -u "$USER" -x konsole || true
systemd-run --user -q konsole --hold -e /tmp/vmwatch-run.sh
for _ in $(seq $((wait / 2))); do [ -f /tmp/wizard.done ] && break; sleep 2; done
[ -f /tmp/wizard.done ] || echo "(still running after ${wait}s)"
sed 's/\x1b\[[0-9;]*m//g' /tmp/wizard.log
REMOTE
} | vm_ssh bash -s 2>&1
