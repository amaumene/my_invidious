FROM alpine AS builder

RUN apk add --no-cache sqlite-static yaml-static yaml-dev libxml2-static \
       zlib-static openssl-libs-static openssl-dev musl-dev xz-static git \
       crystal shards

RUN git clone https://github.com/iv-org/invidious.git /invidious

WORKDIR /invidious

RUN shards update

RUN shards install --production

RUN crystal build ./src/invidious.cr \
    --static --warnings all \
    --link-flags "-lxml2 -llzma"

FROM scratch

WORKDIR /invidious

COPY --from=builder /invidious/config/ ./config/
COPY --from=builder /invidious/config/config.example.yml ./config/config.yml
COPY --from=builder /invidious/locales ./locales/
COPY --from=builder /invidious/assets ./assets/
COPY --from=builder /invidious/invidious .

COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

EXPOSE 3000/tcp

CMD [ "/invidious/invidious" ]
