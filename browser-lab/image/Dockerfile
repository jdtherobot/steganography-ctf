# ============================================================================
#  Badger Lab — bootable v86 image (32-bit Debian userland + full toolkit)
# ============================================================================
# This bakes the EXACT toolchain proven in ../feasibility/i386-toolchain-proof.md
# (Debian i386, versions pinned by the apt snapshot) plus the sanitized player
# files, plus a kernel + serial-autologin init + a 9p-capable initramfs so v86 can
# boot it as a root-over-9p filesystem (the same mechanism as v86's alpine.html).
#
# Build context must contain ./payload/ with the sanitized challenge files —
# build-image.sh assembles it. Never COPY anything from facilitator/ or the archive.
#
# Build (32-bit is mandatory):
#   docker build --platform linux/386 -t badger-lab:i386 .
# Then package to a 9p filesystem with ./build-image.sh (docker export -> fs2json).
# ============================================================================
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN printf 'Acquire::Languages "none";\nAPT::Install-Recommends "false";\n' > /etc/apt/apt.conf.d/99lean \
 && apt-get update

# --- Player toolchain (grouped so no single heavy tree stalls emulated dpkg) ---
RUN apt-get install -y openssl file coreutils xxd unzip zip ca-certificates less nano vim-tiny bash-completion
RUN apt-get install -y steghide
RUN apt-get install -y libimage-exiftool-perl
RUN apt-get install -y python3 binwalk
# setuptools restores the `distutils` shim that Python 3.13 dropped (PEP 632) —
# without it stegcracker 2.1.0 crashes on import. See feasibility/i386-toolchain-proof.md.
RUN apt-get install -y python3-pip \
 && pip install --break-system-packages --no-cache-dir setuptools stegcracker || true

# --- Kernel + init + 9p boot plumbing --------------------------------------
# linux-image-686 = the 32-bit kernel; the 9p modules ship with it. We build an
# initramfs that loads virtio+9p and can mount root=host9p (v86's virtio-9p tag).
RUN apt-get install -y linux-image-686 initramfs-tools

# Make the initramfs carry the virtio + 9p modules and mount 9p as root.
RUN printf '%s\n' 9pnet 9pnet_virtio 9p virtio virtio_pci virtio_ring >> /etc/initramfs-tools/modules
COPY overlay/etc/initramfs-tools/scripts/local-top/9proot /etc/initramfs-tools/scripts/local-top/9proot
RUN chmod +x /etc/initramfs-tools/scripts/local-top/9proot \
 && KREL="$(ls /lib/modules | head -1)" && update-initramfs -u -k "$KREL" || update-initramfs -c -k "$(ls /lib/modules | head -1)"

# Serial-console autologin so the v86 terminal harness lands on a root shell on ttyS0.
# (Uses agetty --autologin; no password prompt — this is a throwaway lab box.)
RUN apt-get install -y util-linux \
 && mkdir -p /etc/systemd/system/serial-getty@ttyS0.service.d \
 && printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin root --noclear %%I 115200 vt100\n' \
      > /etc/systemd/system/serial-getty@ttyS0.service.d/autologin.conf \
 && systemctl enable serial-getty@ttyS0.service 2>/dev/null || true
RUN passwd -d root || true

# --- Sanitized player files (assembled by build-image.sh into ./payload) -----
RUN useradd -m -s /bin/bash player || true
COPY payload/ /home/player/challenges/
RUN chown -R player:player /home/player/challenges \
 && printf '\ncd ~/challenges 2>/dev/null; echo "Badger Lab — challenge files are in ~/challenges. Start with: exiftool stego_badger.jpeg"\n' >> /home/player/.bashrc

# A friendly MOTD.
RUN printf '%s\n' \
  '  ___          _                 _          _     ' \
  ' | _ ) __ _ __| |__ _ ___ _ _   | |   __ _ | |__  ' \
  ' | _ \/ _` / _` / _` / -_) `_|  | |__/ _` || / _ \ ' \
  ' |___/\__,_\__,_\__, \___|_|    |____\__,_||_\___/ ' \
  '                |___/  32-bit forensics workbench   ' \
  > /etc/motd

RUN apt-get clean && rm -rf /var/lib/apt/lists/* /usr/share/doc/* /usr/share/man/* 2>/dev/null || true
