FROM docker.io/archlinux/archlinux:latest AS builder

ENV DRACUT_NO_XATTR=1
RUN pacman -Sy --noconfirm \
      dracut \
      linux \
      linux-firmware \
      ostree \
      systemd \
      btrfs-progs \
      e2fsprogs \
      xfsprogs \
      dosfstools \
      skopeo \
      dbus \
      dbus-glib \
      glib2 \
      shadow \
      fastfetch && \
  pacman -S --clean --noconfirm && \
  rm -rf /var/cache/pacman/pkg/*

# install archbang packages
RUN curl -s 'https://raw.githubusercontent.com/mrgreen3/archbang/refs/heads/main/packages.x86_64' | \
    sed '/grub/d;/os-prober/d;/syslinux/d;/efibootmgr/d;/arch-install-scripts/d;/^mkinitcpio/d;/gparted/d' | \
    grep -vE '^\s*#|^\s*$' | \
    xargs pacman -S --noconfirm --needed && \
    pacman -S --clean --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# Workaround due to dracut version bump, please remove eventually
# FIXME: remove
RUN echo -e "systemdsystemconfdir=/etc/systemd/system\nsystemdsystemunitdir=/usr/lib/systemd/system\n" | tee /etc/dracut.conf.d/fix-bootc.conf

# building bootc with /var check patch
RUN --mount=type=tmpfs,dst=/tmp --mount=type=tmpfs,dst=/root \
    pacman -S --noconfirm base-devel git rust && \
    git clone https://github.com/bootc-dev/bootc.git --depth=1 /tmp/bootc && \
    curl --retry 5 -L https://patch-diff.githubusercontent.com/raw/bootc-dev/bootc/pull/1735.patch -o /tmp/bootc/1735.patch && \
    cd /tmp/bootc && git apply 1735.patch && cd - && \
    make -C /tmp/bootc bin install-all install-initramfs-dracut && \
    sh -c 'export KERNEL_VERSION="$(basename "$(find /usr/lib/modules -maxdepth 1 -type d | grep -v -E "*.img" | tail -n 1)")" && \
    dracut --force --no-hostonly --reproducible --zstd --verbose --kver "$KERNEL_VERSION"  "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"' && \
    pacman -Rns --noconfirm base-devel git rust && \
    pacman -S --clean --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# add archbang customatization
RUN --mount=type=tmpfs,dst=/tmp \
    pacman -S --noconfirm git && \
    git clone https://github.com/mrgreen3/archbang.git --depth=1 /tmp/archbang && \
    rm -rf /tmp/archbang/airootfs/etc/{hosts,locale.conf,mkinitcpio.conf,mkinitcpio.d,passwd,shadow,systemd,skel/AB_Scripts/abinstall} && \
    sed -i '/<!-- abinstall 5 -->/,+5d' /tmp/archbang/airootfs/etc/skel/.config/openbox/menu.xml && \
    sed -i '/GParted/,+4d' /tmp/archbang/airootfs/etc/skel/.config/openbox/menu.xml && \
    cp -r /tmp/archbang/airootfs/etc/* /etc && \
    pacman -Rns --noconfirm git && \
    pacman -S --clean --noconfirm && \
    rm -rf /var/cache/pacman/pkg/*

# Setup a temporary root passwd (changeme) for dev purposes
#RUN pacman -S --noconfirm whois && \
#    usermod -p "$(echo "changeme" | mkpasswd -s)" root && \
#    pacman -Rns --noconfirm whois && \
#    pacman -S --clean --noconfirm && \
#    rm -rf /var/cache/pacman/pkg/*

RUN rm -rf /boot /home /root /usr/local /srv && \
    mkdir -p /var/{home,roothome,srv} /sysroot /boot && \
    ln -s sysroot/ostree /ostree

# Update useradd default to /var/home instead of /home for User Creation
RUN sed -i 's|^HOME=.*|HOME=/var/home|' "/etc/default/useradd"

# Allow people in group wheel to run all commands
RUN mkdir -p /etc/sudoers.d && \
    echo "%wheel ALL=(ALL) ALL" | \
    tee "/etc/sudoers.d/wheel"

# Necessary for `bootc install`
RUN mkdir -p /usr/lib/ostree && \
    printf "[composefs]\nenabled = yes\n[sysroot]\nreadonly = true\n" | \
    tee "/usr/lib/ostree/prepare-root.conf"

RUN bootc container lint
