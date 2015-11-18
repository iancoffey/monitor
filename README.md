# Deis Monitor v2

Deis (pronounced DAY-iss) is an open source PaaS that makes it easy to deploy and manage applications on your own servers. Deis Monitor aims to consolidate best practices to produce a streamlined monitoring and telemetry system based on Prometheus.

## Work in Progress

![Deis Graphic](https://s3-us-west-2.amazonaws.com/get-deis/deis-graphic-small.png)

Deis Monitor is changing quickly. Your feedback and participation are more than welcome, but be aware that this project is considered a work in progress.

## Hacking Workflow

To hack on Monitor, it is necessary to have a local Kubernetes cluster up. Follow the [Kubernetes docs](https://github.com/kubernetes/kubernetes/blob/master/docs/getting-started-guides/vagrant.md#setup) to a Vagrant cluster booted.

If you dont already have a local dev registry up you boot one like so:

```console
$ docker-machine create --driver virtualbox --virtualbox-disk-size=100000 --engine-insecure-registry=192.168.0.0/16 deis-registry
```

Next, create the dev-registry container:
```console
make dev-registry
```

To make the Kubernetes Docker daemons able to use your new insecure local registry, add the necessary insecure-registry options to DOCKER_OPTS:

```console
DOCKER_OPTS='-b=cbr0 --insecure-registry 192.168.0.0/16'
OPTIONS='-b=cbr0 --insecure-registry 192.168.0.0/16'
DOCKER_CERT_PATH=/etc/docker
```

This will require a Docker restart to take effect.

Now set up your environment:
```console
eval "$(docker-machine env deis-registry)"
export DEV_REGISTRY=192.168.99.101:5000
```

Next install the [deis/etcd cluster according to its documentation](https://github.com/deis/etcd#usage), push the image to your new local dev registry and ensure its started by inspecting its pods.

Now, you can build the Docker images for the project, push to the local dev registry.

```console
$ make build && make push
```

Finally, start the services like so:

```console
$ make kube-create-all
```
