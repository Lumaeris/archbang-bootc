# ArchBang Bootc

An experiment with including some more packages of Arch-based distro and overwriting some system files. Based on bootcrew's [arch-bootc](https://github.com/bootcrew/arch-bootc). bootc cli was slightly patched in order to make `switch` and `upgrade` work (https://github.com/bootc-dev/bootc/pull/1735). While `switch` worked, I can't say the same for `upgrade` just yet.

<img width="1024" height="768" alt="image" src="https://github.com/user-attachments/assets/adfb82f2-c3ce-4b2d-a301-653e46d1713e" />

## Why

idk I'm bored. While thinking of some Arch-based distros I've got CachyOS, EndeavourOS and of course ArchBang (which apparently was called GreenBang at one point). Maybe I'll try redoing this experiment with some other distros just for fun.

## Building

In order to get a running arch-bootc system you can run the following steps:
```shell
just build-containerfile # This will build the containerfile and all the dependencies you need
just generate-bootable-image # Generates a bootable image for you using bootc!

useradd -m -G wheel -s /bin/bash user # in order to create an user account in live system
```

Then you can run the `bootable.img` as your boot disk in your preferred hypervisor.
