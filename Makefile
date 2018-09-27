# Copyright 2018 The Caicloud Authors.
#
# Usage:
#   make                 - default to 'release-image' target
#   make release-image   - build and push release image
#   make update-tag      - get latest tag from repo and generate release_charts.yaml
#   make collect-charts  - collect charts from all repos
#

# Golang standard bin directory.
BIN_DIR := $(GOPATH)/bin
AMCTL := $(BIN_DIR)/amctl

# commitish
TAG = $(shell git describe --tags --always --dirty)

# RELEASE_VERSION is the version of the release
PANGOLIN_VERSION           ?= v0.0.2
RELEASE_VERSION            ?= $(TAG)

# Build and push specific variables.
REGISTRY ?= cargo-infra.caicloud.xyz
PROJECT  ?= devops_release
PUSH     ?= docker push

PANGOLIN_IMAGE ?= $(REGISTRY)/$(PROJECT)/pangolin:$(PANGOLIN_VERSION)

DOCKER_LABELS=--label compass-release.git-describe="$(shell date -u +v%Y%m%d)-$(shell git describe --tags --always --dirty)"

release-image:
	# set platform release info in platform-info
	sed -i- "s|G_PLATFORM_RELEASE_VERSION|\"${RELEASE_VERSION}\"|g" platform-info.yaml.j2
	sed -i- "s|G_PLATFORM_RELEASE_TIME|\"$(shell date +'%Y-%m-%d %H:%M')\"|g" platform-info.yaml.j2 && rm platform-info.yaml.j2-
	# build release-image
	sed -i- "s|PANGOLIN_IMAGE|$(PANGOLIN_IMAGE)|g" build/release/Dockerfile && rm build/release/Dockerfile-
	docker build -t "$(REGISTRY)/$(PROJECT)/release:$(RELEASE_VERSION)" $(DOCKER_LABELS) -f build/release/Dockerfile .
	$(PUSH) "$(REGISTRY)/$(PROJECT)/release:$(RELEASE_VERSION)"

$(AMCTL):
	go get github.com/caicloud/pangolin/cmd/amctl
	amctl --help &> /dev/null

# update tags in charts_list.yaml
update-tag: $(AMCTL)
	amctl update --config-path=charts_list.yaml --github-token-file=token --target-path=release_charts.yaml

# collect chart from repos
collect-charts: $(AMCTL)
	amctl collect --config-path=release_charts.yaml --github-token-file=token --root-dir=addons

.PHONY: release-image update-tag collect-charts
