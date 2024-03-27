If on Windows, launch WSL for unix-style device binding:

```sh
> wsl
$
```

Then, use Docker to run the development container:

```sh
$ docker run -it -v "$(pwd)":/os:rw --cap-add SYS_ADMIN --device /dev/loop3 debian:stable-slim bash
```

Now you can run the "flesh it out" script to define a virtual machine disk image from the archived filesystem, filling out the missing pieces of the OS:

```sh
$ flesh /os/flesh.sh
```
