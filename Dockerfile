FROM quay.io/spivegin/golang_dart AS build-env-go110
WORKDIR /opt/src/src/github.com/mholt
ADD caddyhttp/caddyhttp.go /tmp/caddyhttp.go
ADD https://github.com/Masterminds/glide/releases/download/v0.13.2/glide-v0.13.2-linux-amd64.zip /tmp/glide.zip
ADD https://raw.githubusercontent.com/golang/dep/master/install.sh /tmp/dep.sh
RUN git clone https://github.com/caddyserver/builds.git  /opt/src/src/github.com/caddyserver/builds &&\
    git clone https://github.com/mholt/caddy.git 
RUN apt update -y && apt upgrade -y && mkdir /opt/src/bin
RUN sh /tmp/dep.sh && ln -s /opt/src/bin/dep /bin/dep
RUN unzip /tmp/glide.zip -d /opt/ && mkdir /opt/bin &&\
    chmod +x /opt/linux-amd64/glide &&\ 
    ln -s /opt/linux-amd64/glide /bin/glide
RUN cp /tmp/caddyhttp.go /opt/src/src/github.com/mholt/caddy/caddyhttp/ 

    # cd caddy &&\
    # git fetch --all --tags --prune &&\
    # git checkout tags/v0.11.1 -b v0.11.1
# RUN cd caddy && rm -rf vendor && glide init --non-interactive && glide install --force
RUN cd caddy && dep init && dep ensure -vendor-only
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
