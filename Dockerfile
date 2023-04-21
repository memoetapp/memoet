FROM elixir:1.13-alpine as build
ENV MIX_ENV=prod

# To build assets, Rustler
RUN apk add git python3 cargo build-base

# For nodejs
RUN echo "http://dl-cdn.alpinelinux.org/alpine/v3.16/main/" >> /etc/apk/repositories
RUN apk add nodejs=16.20.0-r0 npm=9.1.2-r0 --repository="http://dl-cdn.alpinelinux.org/alpine/v3.16/main/"

COPY mix.exs mix.lock ./
COPY config .
RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get && \
    mix deps.compile

COPY assets/package.json assets/package-lock.json ./assets/
RUN npm ci --prefix ./assets

COPY . .
RUN mix deps.clean mime --build && \
    mix assets.deploy && \
    mix release

FROM elixir:1.13-alpine

# To run Rustler build
RUN apk add --no-cache libgcc

ENV HOME=/opt/app
WORKDIR ${HOME}
COPY --from=build _build/prod/rel/memoet ${HOME}
RUN mkdir -p ${HOME} && \
    adduser -s /bin/sh -u 1001 -G root -h ${HOME} -S -D default && \
    chown -R 1001:0 ${HOME}
ENTRYPOINT ["/opt/app/bin/memoet"]
CMD ["start"]
