# dock2vm

If on Windows, launch WSL for unix-style device binding:

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
$ qemu-system-x86_64 -drive file=dock2vm.img,index=0,media=disk,format=raw
```

The script cleans up mounts and devices, but you can also clean artifacts from this working folder:

```sh
$ git clean -Xfd
```

## Credit

While I'm trying to streamline this, ensure it works on Windows/WSL, and eventually fold into a DigitalOcean custom image with NixOS support, the heavy lifting for this process was derived from an outstanding article by Ivan Velichko:

https://iximiuz.com/en/posts/from-docker-container-to-bootable-linux-disk-image/

## Milestones:

- [x] Should boot from qemu

- [x] Should no longer need "development container" (straight from WSL)

- [x] Do we need separate "os" and "mnt" paths? Sort of, it's primarily a permissions issue.

- [ ] Should be able to "host" from droplet (e.g., cloud-init; sshd; etc.)

- [x] Should extend to Alpine

- [ ] Should extend to NixOS w/ configuration parameterized

- [ ] Should build/register as DigitalOcean custom image (terraform module as git submodule?)

- [ ] Should be able to "spin up" Droplet resources with arbitrary configurations from that custom image
