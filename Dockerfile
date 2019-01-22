FROM quay.io/spivegin/golang:v1.11.4 AS build-env-go110
WORKDIR /opt/src/src/github.com/mholt
ADD caddy_mods/caddyhttp.go.txt /tmp/caddyhttp.go
ADD caddy_mods/run.go.txt /tmp/run.go
ADD caddy_mods/commands.go.txt /tmp/commands.go
RUN apt-get update && apt-get install -y gcc &&\
    go get github.com/caddyserver/builds &&\
    go get github.com/mholt/caddy
# RUN cp /tmp/caddyhttp.go ${GOPATH}/src/github.com/mholt/caddy/caddyhttp/ &&\
ENV GO111MODULE=on
    # cd caddy &&\
    # git fetch --all --tags --prune &&\
    # git checkout tags/v0.11.1 -b v0.11.1
# RUN cd caddy && rm -rf vendor && glide init --non-interactive && glide install --force
RUN cd caddy && git checkout v0.11.1  &&\
    cp /tmp/run.go ${GOPATH}/src/github.com/mholt/caddy/caddy/caddymain/ &&\
    cp /tmp/commands.go ${GOPATH}/src/github.com/mholt/caddy/ &&\
    go mod init && go mod tidy
RUN cd caddy/caddy && go run build.go

FROM quay.io/spivegin/golang_dart_protoc_dev AS build-env-go111
WORKDIR /opt/src/src/github.com/CaddyWebPlugins/

ENV GO111MODULE=on

RUN git clone https://github.com/CaddyWebPlugins/caddystart.git &&\
    cd caddystart && go mod tidy &&\
    go get ./... &&\
    go build -o caddystart main.go

FROM quay.io/spivegin/tlmbasedebian
RUN mkdir -p /opt/bin
COPY --from=build-env-go110 /opt/src/src/github.com/mholt/caddy/caddy/caddy /opt/bin/caddy
COPY --from=build-env-go111 /opt/src/src/github.com/CaddyWebPlugins/caddystart /opt/bin/caddystart
WORKDIR /opt/caddy/
RUN chmod +x /opt/bin/caddy && chmod +x /opt/bin/caddystart/caddystart &&\
    ln -s /opt/bin/caddy /bin/caddy &&\
    ln -s /opt/bin/caddystart/caddystart /bin/caddystart 
ENV DEBUG=false \
    EMAIL=ssl@changeme.com \
    TESTING=true
CMD ["caddystart"]
