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
$ qemu-system-x86_64 -drive file=dock2vm.qcow2,index=0,media=disk,format=qcow2,if=virtio
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

- [x] Should be able to "host" from droplet (e.g., cloud-init; sshd; etc.)

- [x] Should extend to Alpine

- [ ] Should extend to NixOS w/ configuration parameterized

- [x] Should build/register as DigitalOcean custom image

- [x] Should be able to "spin up" Droplet resources with arbitrary configurations from that custom image

- [x] Add compression pass to `.img` artifact

- [ ] Look into any other modifications to the build script that could theoretically be pulled into the Dockerfile specification

- [x] A lot of Dockerfile modifications (permissions, etc.) are probably OBE now

- [ ] Looks like root:root is still working on droplet from console, so passwordless isn't being enforced (see cloud-init configuration requirements)

- [ ] We can log in with the above credentials in the Console but SSH (while the daemon is running) cannot be used to connect

- [ ] It looks like cloud-init is not correctly configuring DHCP, which we may need to do from the image construction ourselves

- [ ] It would be useful to verify that the DigitalOcean-defined keys are in fact being correctly installed

- [ ] At some point, optionally, it would be nice to automate a lot of this as a Terraform process in which specific DigitalOcean VM instances can be defined with a procedurally-uploaded cstom image

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

* Total storage used by custom images is not readily visible within the DigitalOcean platform; neither will the image upload window display the current size

* Custom image VMs on DigitalOcean neither receive an anchor IP address nor do they require one to us a reserved IP; an IP is automatically mapped to the VM's public IPv4 address instead

* Importing a custom image by URL will fail if the image is served by a CDN that doesn't support HEAD requests, and therefore may require manual download/upload

* Monitoring (within the DigitalOcean platform) must be enabled manually

* Device naming is slightly different; DigitalOcean uses `/dev/vda1` for root filesystem, not `/dev/sda1`, but QEMU may require explicit instructions to do the same (README example updated)

## Uploading

At this stage, we have a functional VM image that can be run locally with QEMU. But, you can also upload it to DigitalOcean now (progress!) and use it to spin up a VM.

1. Run the build script, which should gneerate a `.QCOW2` file in this folder

1. In your DigitalOcean dashboard, under "Backup & Snapshots", select the "Custom Images" tab and click "Upload Image"

1. Select the `.QCOW2` file; in the subsequent options, set the distribution to "Unknown" (Alpine, the default base, isn't an option) and click "Upload Image" when you're done

1. Once the image upload process has complete (an entry will be listed it's "Uploaded" status will no longer be "Pending"), click the "More" button to the side of that entry and click "Start a droplet"

1. The droplet, once started, can be directly accessed (provided cloud-init has enabled it) via the "Console" option

## Debugging

Currently stuck in initially-readonly-on-boot, here are potential fixes from https://github.com/iximiuz/docker-to-linux/issues/19 :

- [x] Scripted include of drive UUID in `fstab`?

- [ ] Try a differen OS for reference (Ubuntu/Debian)?

- [ ] "Remount" script to be run by `local` service via OpenRC?

- [x] Verify .docker files are removed from final VM before boot?

- [ ] `dev` service dependency and/or running `/etc/init.d/root start`?

- [ ] Explicitly enable services needed for boot process?

If the cloud-init execution is delayed in the boot process until after the root filesystem is remounted in read-write mode, then it does appear to execute successfully. This appears to happen when `chronyd` is enabled, but this fails to boot completely because the time server requests subsequently put the boot sequence into an infinite loop of failed network requests.

At time of this commt, we have a secondary openrc script and some `sed` commands in the Dockerfile build that attempt to force a postponment of cloud-init until after the root filesystem is remounted. However, this will likely not address the underlying issue with `chronyd`, which should not be attempting to hijack a boot dependency when no network connection exists.

*UPDATE*: Nope, that didn't work. Should reverts remount script and Dockerfile hooks.
