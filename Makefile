ifndef BUILD_TAG
  BUILD_TAG = git-$(shell git rev-parse --short HEAD)
endif

# images name spaced under monitor, for now.
COMPONENT = monitor

# all this naming needs more thought
REGISTRY = $(shell if [ "$$DEV_REGISTRY" == "registry.hub.docker.com" ]; then echo; else echo $$DEV_REGISTRY/; fi)
IMAGE_PREFIX = deis/
PROM_IMAGE = $(IMAGE_PREFIX)$(COMPONENT)-prometheus:$(BUILD_TAG)
PROM_DEV_IMAGE = $(REGISTRY)$(PROM_IMAGE)
ALERTMANAGER_IMAGE = $(IMAGE_PREFIX)$(COMPONENT)-alert:$(BUILD_TAG)
ALERTMANAGER_DEV_IMAGE = $(REGISTRY)$(ALERTMANAGER_IMAGE)

check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi

build: docker-build

push: docker-push

docker-build: check-docker
	docker build --rm -t $(PROM_IMAGE) prometheus/rootfs
	docker build --rm -t $(ALERTMANAGER_IMAGE) alertmanager/rootfs

docker-push: update-manifests
	docker tag -f $(PROM_IMAGE) $(PROM_DEV_IMAGE)
	docker push $(PROM_DEV_IMAGE)
	docker tag -f $(ALERTMANAGER_IMAGE) $(ALERTMANAGER_DEV_IMAGE)
	docker push ${PROM_DEV_IMAGE}
	docker push ${ALERTMANAGER_DEV_IMAGE}

kube-delete-prometheus:
	-kubectl delete service deis-monitor-prometheus
	-kubectl delete rc deis-monitor-prometheus

kube-delete-alertmanager:
	-kubectl delete service deis-monitor-alert
	-kubectl delete rc deis-monitor-alert

kube-delete-all: kube-delete-alertmanager kube-delete-prometheus

kube-create-prometheus:
	kubectl create -f manifests/deis-monitor-prometheus-rc.tmp.yaml
	kubectl create -f manifests/deis-monitor-prometheus-service.yaml

kube-create-alertmanager:
	kubectl create -f manifests/deis-monitor-alert-rc.yaml
	kubectl create -f manifests/deis-monitor-alert-service.yaml

kube-create-all: kube-create-alertmanager kube-create-prometheus

update-manifests:
	sed 's#\(image:\) .*#\1 $(PROM_DEV_IMAGE)#' manifests/deis-monitor-prometheus-rc.yaml \
		> manifests/deis-monitor-prometheus-rc.tmp.yaml
	sed 's#\(image:\) .*#\1 $(ALERTMANAGER_DEV_IMAGE)#' manifests/deis-monitor-alert-rc.yaml \
		> manifests/deis-monitor-alert-rc.tmp.yaml

clean: check-docker
	docker rmi $(PROM_IMAGE)
	docker rmi $(ALERTMANAGER_IMAGE)

test: test-unit test-functional

test-unit:
	@echo "No unit tests yet :("

test-functional:
	@echo "Implement functional tests in _tests directory"

