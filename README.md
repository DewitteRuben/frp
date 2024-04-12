# Record Evolution Tunnel

This is a fork of the frp repository, which includes additions required for the Record Evolution platform.

# Build 

## Build client 

`make build`


## Build client in Docker

`make build-all-docker`

# Release

Make sure to update the `version.txt` and `availableVersions.json` files to reflect the latest versions

## Build and publish current version

`make rollout`