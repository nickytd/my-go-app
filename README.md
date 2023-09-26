# my-go-app Sample golang project

This is a simple project directory layout. A starting point for golang projects.

It provides a `Makefile` for building the project binary and a `Dockerfile` for building multi-platform container images. The [Makefile](Makefile) provides targets for linting and testing the application, including ginkgo support.

In the Makefile change the following variables:

- `BINARY` to the intended application name. (Default value is `my-go-app`)
- `REGISTRY` to the target docker registry. (Default value is `docker.io`)

In the `go.mod` adjust the module name.

The [Dockerfile](Dockerfile) provides multi platform container image builds for `linux/amd64` and `linux/arm64` by default. It uses  [docker buildx](https://docs.docker.com/build/building/multi-platform/) to provide multiplatform container image build. It uses container image build cache to optimize the building process.

The intend is to provide an easy start for project development and shall be extended according the concrete needs and requirements.
