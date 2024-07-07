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

Other useful DigitalOcean resources include a high-level overview of VM compatiblity requirements:

https://docs.digitalocean.com/products/images/custom-images/details/features/

And additional details about what constraints on custom VM images exist:

https://docs.digitalocean.com/products/images/custom-images/details/limits/

I can also recommend a great talk by Mason Egger on the subject of custom VM images for DigitalOcean droplets:

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

- [x] Should extend to Alpine

- [ ] Should extend to NixOS w/ configuration parameterized

- [ ] Should build/register as DigitalOcean custom image

- [ ] Should be able to "spin up" Droplet resources with arbitrary configurations from that custom image

- [x] Add compression pass to `.img` artifact

- [ ] Look into any other modifications to the build script that could theoretically be pulled into the Dockerfile specification

- [ ] A lot of Dockerfile modifications (permissions, etc.) are probably OBE now

## Compatibility

### Checklist

These are VM image compatibility requirements aggregated from various sources, and serve as a checklist for working the current VM image into something that can be deployed autonomously:

- [x] Images must have a Unix-like OS (Windows images are not supported)

- [x] Image file format must be one of: raw (`.IMG`), `.qcow2`, `.VHDX`, `.VDI`, or `.VMDK`; `ISO` images are not currently supported

- [x] Images must be 100 GB or less when uncompressed, including the filesystem

- [x] `cloud-init` must be installed (v0.77 or higher); other alternatives include `cloudbase-init`, `coreos-cloudinit`, `ignition`, or `bsd-cloudinit`.

- [x] The default `cloud-init` configuration must not list the `NoCloud` data source before the `ConfigDrive` data source

- [x] SSH (`sshd`) must be installed and configured to run on boot

- [ ] DigitalOcean VMs created from custom images use DHCP to obtain an IP address; no additional network configuration should be necessary, but IPv6 is not supported

- [x] An SSH key must be added when creating a VM from a custom image; password authentication is disabled by default

- [ ] DHCP support is provided on port 67 in the DigitalOcean platform; if a firewall is in place, an outbound UDL exception is required to enable this traffic

- [x] VMs must be started from the same cloud region where the custom image they use was uploaded

### Other Notes

- [ ] Total storage used by custom images is not readily visible within the DigitalOcean platform; neither will the image upload window display the current size

- [ ] Custom image VMs on DigitalOcean neither receive an anchor IP address nor do they require one to us a reserved IP; an IP is automatically mapped to the VM's public IPv4 address instead

- [ ] Importing a custom image by URL will fail if the image is served by a CDN that doesn't support HEAD requests, and therefore may require manual download/upload

- [ ] Monitoring (within the DigitalOcean platform) must be enabled manually

### Debugging Lessons

- [ ] Device naming is slightly different; DigitalOcean uses `/dev/vda1` for root filesystem, not `/dev/sda1`
