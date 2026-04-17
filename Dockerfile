FROM caddy:builder AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/bunny \
    --with github.com/mholt/caddy-dynamicdns \
    --with github.com/hslatman/caddy-crowdsec-bouncer/http
FROM caddy:latest
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
