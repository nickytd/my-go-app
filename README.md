# my-go-app

This is a simple project directory layout. A starting point for golang projects.

It provides a `Makefile` for building the project binary and a `Dockerfile` for building a container image. The [Makefile](Makefile) provides targets for linting and testing the application.

In the Makefile change the following variables:

- `BINARY` to the intended application name. (Default value is `my-go-app`)
- `REGISTRY` to the target docker registry. (Default value is `docker.io`)

In the `go.mod` adjust the module name.

The [Dockerfile](Dockerfile) provides multi platform container image builds for linux/amd64 and linux/arm64. It depends on [docker buildx](https://docs.docker.com/build/building/multi-platform/)

The intend is to provide an easy project start and shall be extended according the concrete project needs.
