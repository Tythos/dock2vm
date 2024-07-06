# dock2vm

If on Windows, launch WSL for unix-style device binding (e.g., loop devices, shell mounting, bootloader configurations):

```sh
> wsl
$
```

You can then run the build script to "flesh out" the Dockerfile from an archive into a full VM image:

```sh
$ source build.sh
```

Finally, test the virtual machine image with qemu:

```sh
$ qemu-system-x86_64 -drive file=dock2vm.qcow2,index=0,media=disk,format=qcow2
```

The script cleans up mounts and devices, but you can also clean all file artifacts (including ignored images) from this working folder even if the process is interrupted:

```sh
$ git clean -Xfd
```

## Customization

The purpose of this project is to provide a means for spinning up arbitrary container-defined virtual machines on a cloud provider (e.g., DigitalOcean).

However, if the image defined in `Dockerfile` changes, there are a few considerations.

Specifically, the boot configuration (`syslinux.cfg` by default) is specific to Alpine-based images, which are a common choice for lightweight container services.

Other base images, like Ubuntu or Debian, may require different boot configurations; consult your desired system's `syslinux.cfg` configuration more details.

Because the purpose of the process is to generate arbitrary VM images from a Dockerfile configuration, you should carefully consider with any modifications how they could be included in the Dockerfile specification; this is highly preferable to modifying the `build.sh` process, which is somewhat fragile.

## Credit

While I'm trying to streamline this, ensure it works on Windows/WSL, and eventually fold into a DigitalOcean custom image with NixOS support, the heavy lifting for this process was derived from an outstanding article by Ivan Velichko:

https://iximiuz.com/en/posts/from-docker-container-to-bootable-linux-disk-image/

Other useful DigitalOcean resources include:

https://docs.digitalocean.com/products/images/custom-images/details/limits/

https://docs.digitalocean.com/products/images/custom-images/details/features/

And a great talk by Mason Egger:

https://www.youtube.com/watch?v=_Wk3jMKLQ1I

Some relevant resources on OpenStack VM image specifications:

https://docs.openstack.org/image-guide/openstack-images.html

There are also several useful articles on custom Droplet kernel management requirements:

https://docs.digitalocean.com/products/droplets/how-to/kernel/

## Milestones:

- [x] Should boot from qemu

- [x] Should no longer need "development container" (straight from WSL)

- [x] Do we need separate "os" and "mnt" paths? Sort of, it's primarily a permissions issue.

- [ ] Should be able to "host" from droplet (e.g., cloud-init; sshd; etc.)

      - [ ] When spinning up droplet: `/dev/sda1: Can't lookup blockdev; mounting... on /sysroot failed: no such file; mounting root: failed; initramfs emergency recovery shell launched`

      - [ ] May need to switch bootloaders from extlinux to grub?

- [x] Should extend to Alpine

- [ ] Should extend to NixOS w/ configuration parameterized

- [ ] Should build/register as DigitalOcean custom image

- [ ] Should be able to "spin up" Droplet resources with arbitrary configurations from that custom image

- [x] Add compression pass to `.img` artifact

- [ ] Look into any other modifications to the build script that could theoretically be pulled into the Dockerfile specification
