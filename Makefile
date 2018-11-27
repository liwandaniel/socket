# Copyright 2018 The Caicloud Authors.
#
# Usage:
#   make                 - default to 'release-image' target
#   make release-image   - build and push release image
#   make build-image     - build ci base image
#   make lint            - lint all charts
#   make update-tag      - get latest tag from repo and generate release_charts.yaml
#   make collect-charts  - collect charts from all repos
#   make convert-images  - convert images from charts into target file
#

# commitish
TAG = $(shell git describe --tags --always --dirty)

# RELEASE_VERSION is the version of the release
RELEASE_VERSION            ?= $(TAG)
PANGOLIN_VERSION           ?= v0.0.2
JENKINS_VERSION            ?= v0.0.1

ADDONS_PATH                ?= ./addons
CHART_LIST_PATH            ?= ./charts_list.yaml
TARGET_IMGAES_LIST_PATH    ?= ./images-lists/images_platform.list
TARGET_COLLECT_TAG_PATH    ?= ./release_charts.yaml
GITHUB_TOKEN_PATH          ?= ./token

# Build and push specific variables.
REGISTRY ?= cargo.caicloudprivatetest.com
PROJECT  ?= caicloud
PUSH     ?= docker push

PANGOLIN_IMAGE ?= $(REGISTRY)/$(PROJECT)/pangolin:$(PANGOLIN_VERSION)

DOCKER_LABELS=--label product-release.git-describe="$(shell date -u +v%Y%m%d)-$(shell git describe --tags --always --dirty)"

release-image:
	# set platform release info in platform-info
	sed -i- "s|G_PLATFORM_RELEASE_VERSION|\"${RELEASE_VERSION}\"|g" platform-info.yaml.j2
	sed -i- "s|G_PLATFORM_RELEASE_TIME|\"$(shell date +'%Y-%m-%d %H:%M')\"|g" platform-info.yaml.j2 && rm platform-info.yaml.j2-
	# build release-image
	sed -i- "s|PANGOLIN_IMAGE|$(PANGOLIN_IMAGE)|g" build/release/Dockerfile && rm build/release/Dockerfile-
	docker build -t "$(REGISTRY)/$(PROJECT)/release:$(RELEASE_VERSION)" $(DOCKER_LABELS) -f build/release/Dockerfile .
	$(PUSH) "$(REGISTRY)/$(PROJECT)/release:$(RELEASE_VERSION)"
	docker tag "$(REGISTRY)/$(PROJECT)/release:$(RELEASE_VERSION)" "release:$(RELEASE_VERSION)"
	docker save "release:$(RELEASE_VERSION)" -o release.tar.gz

build-image:
	@echo "There are some prerequesties, please read the Dockerfile for more details."
	docker build --no-cache --build-arg SSH_ID_RSA="$$(cat ~/.ssh/id_rsa)" -t "$(REGISTRY)/$(PROJECT)/golang-jenkins:$(JENKINS_VERSION)" $(DOCKER_LABELS) -f build/jenkinsfile-base/Dockerfile .
	$(PUSH) "$(REGISTRY)/$(PROJECT)/golang-jenkins:$(JENKINS_VERSION)"

# Golang standard bin directory.
BIN_DIR := $(GOPATH)/bin

RELEASELINT := $(BIN_DIR)/release-cli

$(RELEASELINT):
	go get github.com/caicloud/rudder/cmd/release-cli

lint: $(RELEASELINT)
	@git submodule init
	@git submodule update
	@./hack/lint/lint.sh addons
	@./hack/lint/lint.sh oem_addons

AMCTL := $(BIN_DIR)/amctl

$(AMCTL):
	go get github.com/caicloud/pangolin/cmd/amctl
	amctl --help &> /dev/null

# update tags in charts_list.yaml
update-tag: $(AMCTL)
	amctl update --config-path=$(CHART_LIST_PATH) --github-token-file=$(GITHUB_TOKEN_PATH) --target-path=$(TARGET_COLLECT_TAG_PATH)

# collect chart from repos
collect-charts: $(AMCTL)
	amctl collect --config-path=$(TARGET_COLLECT_TAG_PATH) --github-token-file=$(GITHUB_TOKEN_PATH) --root-dir=$(ADDONS_PATH)

# convert images from charts into image.list
convert-images: $(AMCTL)
	amctl convert --addons-path=$(ADDONS_PATH) --export=$(TARGET_IMGAES_LIST_PATH)

.PHONY: release-image build-image lint update-tag collect-charts convert-images
