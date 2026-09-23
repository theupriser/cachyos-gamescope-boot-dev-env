# Download the latest CachyOS desktop ISO to cachyos.iso and verify its checksum.
# Windows version of get-iso.sh; re-running resumes a partial download.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$mirror = if ($env:MIRROR) { $env:MIRROR } else { 'https://nl.mirror.cx/cachyos' }

$page = (Invoke-WebRequest -UseBasicParsing https://cachyos.org/download/).Content
$m = [regex]::Match($page, 'ISO/desktop/[0-9]+/cachyos-desktop-linux-[0-9]+\.iso')
if (-not $m.Success) { throw 'Could not find the current ISO on cachyos.org/download' }
$url = "$mirror/$($m.Value)"
$name = Split-Path $m.Value -Leaf
Write-Host "Latest release: $name"

if ((Test-Path cachyos.iso) -and ((Get-Content cachyos.iso.version -ErrorAction SilentlyContinue) -ne $name)) {
    Write-Host 'Existing cachyos.iso is an older release, replacing it.'
    Remove-Item cachyos.iso
}

# curl.exe ships with Windows 10+ and supports resuming (-C -).
curl.exe -fL -C - -o cachyos.iso $url
if ($LASTEXITCODE -ne 0) { throw 'Download failed' }
Set-Content cachyos.iso.version $name

Write-Host 'Verifying checksum...'
$expected = ((curl.exe -fsL "$url.sha256") -split '\s+')[0]
$actual = (Get-FileHash cachyos.iso -Algorithm SHA256).Hash
if ($actual -ieq $expected) { Write-Host 'cachyos.iso: OK' } else { throw "Checksum mismatch: $actual" }
