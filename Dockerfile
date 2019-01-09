FROM quay.io/spivegin/golang:v1.10.7 AS build-env-go110
WORKDIR /opt/src/src/github.com/mholt
ADD caddyhttp/caddyhttp.go /tmp/caddyhttp.go
RUN go get github.com/caddyserver/builds &&\
    go get github.com/mholt/caddy
RUN cp /tmp/caddyhttp.go ${GOPATH}/src/github.com/mholt/caddy/caddyhttp/ 

    # cd caddy &&\
    # git fetch --all --tags --prune &&\
    # git checkout tags/v0.11.1 -b v0.11.1
# RUN cd caddy && rm -rf vendor && glide init --non-interactive && glide install --force
RUN cd caddy && rm -rf vendor && dep init && dep ensure
RUN cd caddy && go build -o caddy caddy.go 

FROM quay.io/spivegin/golang_dart_protoc_dev AS build-env-go111
WORKDIR /opt/src/src/github.com/CaddyWebPlugins/

ENV GO111MODULE=on

RUN git clone https://github.com/CaddyWebPlugins/caddystart.git &&\
    cd caddystart && go mod tidy &&\
    go get ./... &&\
    go build -o caddystart main.go

FROM quay.io/spivegin/tlmbasedebian
RUN mkdir -p /opt/bin
COPY --from=build-env-go110 /opt/src/src/github.com/mholt/caddy/caddy /opt/bin/caddy
COPY --from=build-env-go111 /opt/src/src/github.com/CaddyWebPlugins/caddystart /opt/bin/caddystart
WORKDIR /opt/caddy/
RUN chmod +x /opt/bin/caddy && chmod +x /opt/bin/caddystart &&\
    chmod +x /opt/bin/caddy && chmod +x /opt/bin/caddy &&\
    ln -s /opt/bin/caddy /bin/caddy &&\
    ln -s /opt/bin/caddy /bin/caddystar 
ENV DEBUG=false \
    EMAIL=ssl@changeme.com \
    TESTING=true
CMD ["caddystart"]
