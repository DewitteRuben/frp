#!/bin/bash

array=($(ls build))
VERSION=`cat version.txt`

for element in "${array[@]}"; do
    OS=$(echo "$element" | cut -d "-" -f 2)
    ARCH=$(echo "$element" | cut -d "-" -f 3)
    BINARY_NAME="frpc"

    if [ "$OS" == "windows" ]; then
        BINARY_NAME="frpc.exe"
    fi

    GCLOUD="gs://frpc/${OS}/${ARCH}/${VERSION}/${BINARY_NAME}"
    gsutil cp "build/$element" $GCLOUD
done

gsutil setmeta -r -h "Cache-control:public, max-age=0" gs://frpc