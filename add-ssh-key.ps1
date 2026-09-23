# Windows: authorize your SSH key in the VM (asks for the VM password once).
# Run after guest-ssh-setup.sh inside the VM, or at least after sshd is enabled there.
#   .\add-ssh-key.ps1 -User <vm-user>
param([Parameter(Mandatory)][string]$User)
$ErrorActionPreference = 'Stop'
$key = Join-Path $env:USERPROFILE '.ssh\id_ed25519.pub'
if (-not (Test-Path $key)) { ssh-keygen -t ed25519 -f ($key -replace '\.pub$', '') -N '""' }
Get-Content $key | ssh -p 2222 "$User@localhost" 'install -d -m 700 ~/.ssh && k=$(cat) && (grep -qxF "$k" ~/.ssh/authorized_keys 2>/dev/null || echo "$k" >> ~/.ssh/authorized_keys) && chmod 600 ~/.ssh/authorized_keys'
Write-Host "Done. Connect with: ssh -p 2222 $User@localhost"
