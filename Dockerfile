FROM quay.io/spivegin/golang_dart_protoc_dev AS build-env
WORKDIR /opt/src/src/github.com/mholt
ADD caddyhttp/caddyhttp.go /tmp/caddyhttp.go

ENV GO111MODULE=on

RUN git clone https://github.com/caddyserver/builds.git  /opt/src/src/github.com/caddyserver/builds &&\
    git clone https://github.com/mholt/caddy.git 

RUN cp /tmp/caddyhttp.go /opt/src/src/github.com/mholt/caddy/caddyhttp/ &&\
    cd caddy && go mod tidy &&\
    go get ./... &&\
    go build -o caddy caddy.go 

RUN mkdir -p /opt/src/src/github.com/CaddyWebPlugins/ &&\ 
    cd /opt/src/src/github.com/CaddyWebPlugins/ &&\
    git clone https://github.com/CaddyWebPlugins/caddystart.git &&\
    cd caddystart && go mod tidy &&\
    go get ./... &&\
    go build -o caddystart main.go

FROM quay.io/spivegin/tlmbasedebian
RUN mkdir -p /opt/bin
COPY --from=build-env /opt/src/src/github.com/mholt/caddy/caddy /opt/bin/caddy
COPY --from=build-env /opt/src/src/github.com/CaddyWebPlugins/caddystart /opt/bin/caddystart
WORKDIR /opt/caddy/
RUN chmod +x /opt/bin/caddy && chmod +x /opt/bin/caddystart &&\
    chmod +x /opt/bin/caddy && chmod +x /opt/bin/caddy &&\
    ln -s /opt/bin/caddy /bin/caddy &&\
    ln -s /opt/bin/caddy /bin/caddystar 
ENV DEBUG=false \
    EMAIL=ssl@changeme.com \
    TESTING=true
CMD ["caddystart"]
