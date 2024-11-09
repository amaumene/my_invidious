FROM registry.access.redhat.com/ubi9 AS builder

RUN curl -s https://packagecloud.io/install/repositories/84codes/crystal/script.rpm.sh | bash

RUN dnf install crystal-1.12.2-139 git sqlite-devel openssl-devel libxml2-devel libyaml-devel zlib-devel glibc-devel libevent-devel pcre-devel -y

WORKDIR /app

RUN git clone https://github.com/catspeed-cc/invidious.git

WORKDIR /app/invidious

#RUN git checkout $(git describe --tags `git rev-list --tags --max-count=1`)

RUN shards install --production
RUN crystal build ./src/invidious.cr --release
#RUN crystal build ./src/invidious.cr --release --static --warnings all --link-flags "-lxml2 -llzma"
RUN ls -lah

FROM registry.access.redhat.com/ubi9/ubi-minimal

WORKDIR /app

COPY --from=builder /app/invidious/invidious /app/

COPY --from=builder /app/invidious/config/config.example.yml /app/config/config.yml
RUN sed -i 's/host: \(127.0.0.1\|localhost\)/host: invidious-db/' /app/config/config.yml
COPY --from=builder /app/invidious/config/sql/ /app/config/sql/
COPY --from=builder /app/invidious/locales/ /app/locales/
COPY --from=builder /app/invidious/assets /app/assets/

EXPOSE 3000/tcp

USER 1001

CMD [ "/app/invidious" ]
