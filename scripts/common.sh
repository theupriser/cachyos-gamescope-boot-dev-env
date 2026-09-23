# Sourced by the other scripts: SSH target of the test VM.
VM_USER="${VM_USER:-theupriser}"
VM_PORT="${VM_PORT:-2222}"
VM_HOST="${VM_HOST:-localhost}"
vm_ssh() { ssh -p "$VM_PORT" -o BatchMode=yes "$VM_USER@$VM_HOST" "$@"; }
