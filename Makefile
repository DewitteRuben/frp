export PATH := $(PATH):`go env GOPATH`/bin
export GO111MODULE=on
LDFLAGS := -s -w

ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

all: env fmt build

build: frps frpc

build-all:
	scripts/build-all.sh

build-all-docker: clean-build ## Builds all docker images for all targets in targets files
	docker build --platform linux/amd64 . -t frpc-builder
	docker run --name agent_builder -v ${ROOT_DIR}/build:/app/frpc/build frpc-builder

clean-build:
	docker rm -f agent_builder
	rm -f build/*

publish-all: publish publish-version publish-latestVersions ## publish the metadata and binaries from the build folder

rollout: build-all-docker publish publish-version publish-latestVersions ## Do everythin in one step

publish:
	scripts/publish.sh

publish-version:
	gsutil cp "version.txt" gs://frpc
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://frpc/version.txt

publish-latestVersions:
	gsutil cp "availableVersions.json" gs://frpc
	gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://frpc/availableVersions.json

env:
	@go version

# compile assets into binary file
file:
	rm -rf ./assets/frps/static/*
	rm -rf ./assets/frpc/static/*
	cp -rf ./web/frps/dist/* ./assets/frps/static
	cp -rf ./web/frpc/dist/* ./assets/frpc/static

fmt:
	go fmt ./...

fmt-more:
	gofumpt -l -w .

gci:
	gci write -s standard -s default -s "prefix(github.com/fatedier/frp/)" ./

vet:
	go vet ./...

frps:
	env CGO_ENABLED=0 go build -trimpath -ldflags "$(LDFLAGS)" -tags frps -o bin/frps ./cmd/frps

frpc:
	env CGO_ENABLED=0 go build -trimpath -ldflags "$(LDFLAGS)" -tags frpc -o bin/frpc ./cmd/frpc

test: gotest

gotest:
	go test -v --cover ./assets/...
	go test -v --cover ./cmd/...
	go test -v --cover ./client/...
	go test -v --cover ./server/...
	go test -v --cover ./pkg/...

e2e:
	./hack/run-e2e.sh

e2e-trace:
	DEBUG=true LOG_LEVEL=trace ./hack/run-e2e.sh

e2e-compatibility-last-frpc:
	if [ ! -d "./lastversion" ]; then \
		TARGET_DIRNAME=lastversion ./hack/download.sh; \
	fi
	FRPC_PATH="`pwd`/lastversion/frpc" ./hack/run-e2e.sh
	rm -r ./lastversion

e2e-compatibility-last-frps:
	if [ ! -d "./lastversion" ]; then \
		TARGET_DIRNAME=lastversion ./hack/download.sh; \
	fi
	FRPS_PATH="`pwd`/lastversion/frps" ./hack/run-e2e.sh
	rm -r ./lastversion

alltest: vet gotest e2e
	
clean:
	rm -f ./bin/frpc
	rm -f ./bin/frps
	rm -rf ./lastversion
