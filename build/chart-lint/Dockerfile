FROM golang:1.9.2-alpine3.6

RUN apk update && apk add \
        git \
        openssh \
        bash \
        vim \
 && rm -rf /var/cache/apk/*

# Install tools we need
RUN go get github.com/caicloud/rudder/cmd/release-cli

WORKDIR /release-cli

COPY ./hack/lint /release-cli/hack/lint/

CMD ["/bin/bash"]
