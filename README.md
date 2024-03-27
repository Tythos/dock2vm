If on Windows, launch WSL for unix-style device binding:

```sh
> wsl
$
```

Build and export the filesystem from the Docker image:

```sh
$ docker build -t mydebian
$ CID=$(docker run -d mydebian /bin/true)
$ docker export -o linux.tar ${CID}
```

Then, use Docker to run the development container:

```sh
$ docker run -it -v "$(pwd)":/os:rw --cap-add SYS_ADMIN --device /dev/loop3 debian:stable-slim bash
```

Now you can run the "flesh it out" script to define a virtual machine disk image from the archived filesystem, filling out the missing pieces of the OS:

```sh
$ source /os/flesh.sh
```

This should result in a `linux.img` file, which can then be used to launch a virtual machine.
