# https://hub.docker.com/_/golang
FROM golang:1.22-bullseye AS build

ARG BUILD_VERSION=v2.0.0-develop

# Ensure ca-certificates are up to date
RUN update-ca-certificates

# Set the current Working Directory inside the container
RUN mkdir /scratch
WORKDIR /scratch

# Prepare the folder where we are putting all the files
RUN mkdir /app
RUN mkdir ../demia.go

# Copy everything from the current directory to the PWD(Present Working Directory) inside the container
COPY ./inx-faucet .
COPY ./demia.go ../demia.go

# Download go modules
RUN go mod download
RUN go mod verify

# Build the binary
RUN go build -o /app/inx-faucet -a -ldflags="-w -s -X=github.com/iotaledger/inx-faucet/components/app.Version=${BUILD_VERSION}"

# Copy the assets
COPY inx-faucet/config_defaults.json /app/config.json

############################
# Image
############################
# https://console.cloud.google.com/gcr/images/distroless/global/cc-debian12
# using distroless cc "nonroot" image, which includes everything in the base image (glibc, libssl and openssl)
FROM gcr.io/distroless/cc-debian12:nonroot

EXPOSE 8091/tcp

# Copy the app dir into distroless image
COPY --chown=nonroot:nonroot --from=build /app /app

WORKDIR /app
USER nonroot

ENTRYPOINT ["/app/inx-faucet"]
