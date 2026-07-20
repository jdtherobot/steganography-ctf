#!/usr/bin/env bash
# Reliable cross-arch build WITHOUT buildx: `docker run --platform linux/386`
# genuinely emulates i386 (verified this session), so we provision a live i386
# container and `docker commit` it. Produces a real Architecture=386 image.
#
# Usage: build-image-fallback.sh <tag> <platform> <payload_dir>
set -euo pipefail
TAG="${1:-badger-lab:i386}"; PLATFORM="${2:-linux/386}"; PAY="${3:?payload dir}"
CN=badger-lab-provision
docker rm -f "$CN" >/dev/null 2>&1 || true

# Start a long-lived i386 container with the payload mounted in.
docker run -d --platform "$PLATFORM" --name "$CN" -v "$PAY":/payload:ro debian:stable-slim sleep infinity >/dev/null

dex(){ docker exec -e DEBIAN_FRONTEND=noninteractive "$CN" bash -euc "$1"; }

echo "   [i386] apt lean config + update"
dex 'printf "Acquire::Languages \"none\";\nAPT::Install-Recommends \"false\";\n" > /etc/apt/apt.conf.d/99lean; apt-get update -qq'
echo "   [i386] group 1: core"      ; dex 'apt-get install -y -qq openssl file coreutils xxd unzip zip ca-certificates less nano vim-tiny'
echo "   [i386] group 2: steghide"  ; dex 'apt-get install -y -qq steghide'
echo "   [i386] group 3: exiftool"  ; dex 'apt-get install -y -qq libimage-exiftool-perl'
echo "   [i386] group 4: py+binwalk"; dex 'apt-get install -y -qq python3 binwalk'
echo "   [i386] group 5: stegcracker (+setuptools for the py3.13 distutils shim)"; dex 'apt-get install -y -qq python3-pip; pip install --break-system-packages --no-cache-dir setuptools stegcracker || true'
echo "   [i386] kernel + initramfs (9p) + serial autologin"
dex 'apt-get install -y -qq linux-image-686 initramfs-tools util-linux'
dex 'printf "%s\n" 9pnet 9pnet_virtio 9p virtio virtio_pci virtio_ring >> /etc/initramfs-tools/modules'
# copy the 9proot hook in
docker cp "$(dirname "$0")/overlay/etc/initramfs-tools/scripts/local-top/9proot" "$CN":/etc/initramfs-tools/scripts/local-top/9proot
dex 'chmod +x /etc/initramfs-tools/scripts/local-top/9proot; update-initramfs -u -k "$(ls /lib/modules | head -1)" || update-initramfs -c -k "$(ls /lib/modules | head -1)"'
dex 'mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d; printf "[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin root --noclear %%I 115200 vt100\n" > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf; systemctl enable serial-getty@ttyS0.service 2>/dev/null || true; passwd -d root || true'
echo "   [i386] bake sanitized player files"
dex 'useradd -m -s /bin/bash player 2>/dev/null || true; mkdir -p /home/player/challenges; cp -r /payload/. /home/player/challenges/; chown -R player:player /home/player/challenges; printf "\ncd ~/challenges 2>/dev/null; echo \"Badger Lab — files in ~/challenges. Try: exiftool stego_badger.jpeg\"\n" >> /home/player/.bashrc'
dex 'apt-get clean; rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* 2>/dev/null || true'

echo "   [i386] verify arch inside the container"
docker exec "$CN" bash -c 'test "$(getconf LONG_BIT)" = 32 && file -L "$(command -v steghide)" | grep -q "ELF 32-bit"' \
  || { echo "!! provisioned container is not 32-bit"; docker rm -f "$CN"; exit 1; }

echo "   [i386] commit -> $TAG"
docker commit -c 'CMD ["/sbin/init"]' "$CN" "$TAG" >/dev/null
docker rm -f "$CN" >/dev/null
echo "   fallback build complete: $TAG (Architecture=386)"
