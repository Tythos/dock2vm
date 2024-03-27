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

Milestones:

- [x] Should boot from qemu

- [x] Should no longer need "development container" (straight from WSL)

- [ ] Do we need separate "os" and "mnt" paths?

- [ ] Should be able to "host" from droplet (e.g., cloud-init; sshd; etc.)

- [x] Should extend to Alpine

- [ ] Should extend to NixOS w/ configuration parameterized

- [ ] Should build/register as DigitalOcean custom image (terraform module as git submodule?)

- [ ] Should be able to "spin up" Droplet resources with arbitrary configurations from that custom image
