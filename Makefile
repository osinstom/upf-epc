# SPDX-License-Identifier: Apache-2.0
# Copyright 2020-present Open Networking Foundation

PROJECT_NAME             := bess-upf
VERSION                  ?= $(shell cat ./VERSION)

# Note that we set the target platform of Docker images to native
# For a more portable image set CPU=haswell
CPU                      ?= native

# Enable Network Token Function support (see https://networktokens.org for more
# information)
ENABLE_NTF               ?= 0

## Docker related
DOCKER_REGISTRY          ?=
DOCKER_TAG               ?= ${VERSION}
DOCKER_IMAGENAME         := ${DOCKER_REGISTRY}${PROJECT_NAME}:${DOCKER_TAG}
DOCKER_BUILDKIT          ?= 1
DOCKER_BUILD_ARGS        ?= --build-arg MAKEFLAGS=-j$(shell nproc) --build-arg CPU
DOCKER_BUILD_ARGS        += --build-arg ENABLE_NTF=$(ENABLE_NTF)
DOCKER_PULL              ?= --pull

## Docker labels. Only set ref and commit date if committed
DOCKER_LABEL_VCS_URL     ?= $(shell git remote get-url $(shell git remote))
DOCKER_LABEL_VCS_REF     ?= $(shell git diff-index --quiet HEAD -- && git rev-parse HEAD || echo "unknown")
DOCKER_LABEL_COMMIT_DATE ?= $(shell git diff-index --quiet HEAD -- && git show -s --format=%cd --date=iso-strict HEAD || echo "unknown" )
DOCKER_LABEL_BUILD_DATE  ?= $(shell date -u "+%Y-%m-%dT%H:%M:%SZ")

docker-build:
	DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build $(DOCKER_PULL) $(DOCKER_BUILD_ARGS) \
		--target bess \
		--tag ${DOCKER_IMAGENAME} \
		--label org.opencontainers.image.source="https://github.com/omec-project/upf-epc" \
		--label org.label.schema.version="${VERSION}" \
		--label org.label.schema.vcs.url="${DOCKER_LABEL_VCS_URL}" \
		--label org.label.schema.vcs.ref="${DOCKER_LABEL_VCS_REF}" \
		--label org.label.schema.build.date="${DOCKER_LABEL_BUILD_DATE}" \
		--label org.opencord.vcs.commit.date="${DOCKER_LABEL_COMMIT_DATE}" \
		.;

docker-push:
	docker push ${DOCKER_IMAGENAME};

# Change target to bess-build/pfcpiface to exctract src/obj/bins for performance analysis
output:
	DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build $(DOCKER_PULL) $(DOCKER_BUILD_ARGS) \
		--target artifacts \
		--output type=tar,dest=output.tar \
		.;
	rm -rf output && mkdir output && tar -xf output.tar -C output && rm -f output.tar

# Golang grpc/protobuf generation
BESS_PB_DIR ?= go/v1

pb:
	DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) docker build $(DOCKER_PULL) $(DOCKER_BUILD_ARGS) \
		--target pb \
		--output output \
		.;
	cp -a output/bess_pb ${BESS_PB_DIR}

.PHONY: docker-build docker-push output pb
