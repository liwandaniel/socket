FROM golang:1.9.2-alpine3.6 AS build

# Run with `docker build --build-arg SSH_ID_RSA="$(cat ~/.ssh/id_rsa)"`
ARG SSH_ID_RSA

RUN apk add --no-cache git openssh

# Copy RSA key for private repository
# This public key should be added to:
# https://github.com/settings/keys
# You can also follow the guidance:
# https://help.github.com/articles/connecting-to-github-with-ssh/
RUN mkdir -p /root/.ssh && \
    echo "${SSH_ID_RSA}" > /root/.ssh/id_rsa && \
    chmod 600 /root/.ssh/id_rsa

# Force git to use SSH instead of HTTPS
RUN git config --global url."git@github.com:".insteadOf https://github.com/
# Force git to use HTTPS instead of SSH
# git config --global url."https://github.com/".insteadOf git@github.com:

# Skip Host verification for git
RUN echo "StrictHostKeyChecking no" > /root/.ssh/config

# Install tools we need
RUN go get github.com/caicloud/rudder/cmd/release-cli && \
    go get github.com/caicloud/pangolin/cmd/amctl

# This results in a single layer image
# Dockerfile link:
FROM cargo.caicloudprivatetest.com/caicloud/golang-docker:1.10-17.09
LABEL maintainer="baomengjiang@caicloud.io"
COPY --from=build /go/bin /go/bin
