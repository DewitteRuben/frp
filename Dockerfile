FROM golang:1.22-alpine

RUN apk add --no-cache git findutils build-base

WORKDIR /app/frpc

RUN mkdir -p build/

COPY . .

RUN go mod download

ENTRYPOINT [ "scripts/build-all.sh" ]