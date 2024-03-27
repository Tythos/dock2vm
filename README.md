If on Windows, launch WSL for unix-style device binding:

```sh
> wsl
$
```

Build and export the filesystem from the Docker image:

```sh
$ docker build -t dock2vm .
$ CID=$(docker run -d dock2vm /bin/true)
$ docker export -o dock2vm.tar ${CID}
```

Then, use Docker to run the development container:

```sh
$ docker run -it -v "$(pwd)":/os:rw --cap-add SYS_ADMIN --device /dev/loop3 debian:stable-slim bash
```

Now you can run the "flesh it out" script to define a virtual machine disk image from the archived filesystem, filling out the missing pieces of the OS:

```sh
$ source /os/flesh.sh
...
$ exit
```

This should result in a `dock2vm.img` file, which can then be used to launch a virtual machine. You can do so with qemu (again from WSL if on Windows):

```sh
$ sudo apt install -y qemu qemu-system
$ qemu-system-x86_64 -drive file=dock2vm.img,index=0,media=disk,format=raw
```
