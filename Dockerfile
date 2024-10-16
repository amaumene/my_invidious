FROM alpine:latest AS builder

RUN apk add --update --no-cache \
    crystal shards sqlite-static yaml-static yaml-dev libxml2-static zlib-static openssl-libs-static openssl-dev musl-dev xz-static \
    git

ENV repo https://github.com/iv-org/invidious.git

WORKDIR /invidious
RUN git clone ${repo} /invidious
RUN git checkout v2.20240825.2
RUN shards install --production

RUN crystal build ./src/invidious.cr \
        --release \
        --static --warnings all \
        --link-flags "-lxml2 -llzma"

FROM alpine:latest
RUN apk add --update --no-cache \
      xvfb \
      chromium \
      rsvg-convert ttf-opensans \
      py3-pip

COPY ./startup.sh ./
RUN chmod +x /startup.sh

WORKDIR /invidious
RUN addgroup -g 1000 -S invidious && \
    adduser -u 1000 -S invidious -G invidious

COPY --from=builder /invidious/config/config.example.yml ./config/config.yml

COPY --from=builder /invidious/config/sql/ ./config/sql/
COPY --from=builder /invidious/locales/ ./locales/
COPY --from=builder /invidious/assets ./assets/
COPY --from=builder /invidious/invidious .

COPY ./index.py .

RUN pip install nodriver --break-system-packages

RUN chmod o+rX -R ./assets ./config ./locales
RUN chown -R invidious:invidious /invidious

RUN sed -i 's/await self.sleep(0.5)/await self.sleep(20)/' /usr/lib/python3.12/site-packages/nodriver/core/browser.py

EXPOSE 3000
USER invidious

CMD [ "/startup.sh"]
