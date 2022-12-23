FROM elixir:1.13.1-alpine AS build

RUN apk add --no-cache build-base git curl py-pip

WORKDIR /app

RUN mix local.hex --force && \
    mix local.rebar --force

ENV MIX_ENV=prod

COPY mix.exs mix.lock ./
COPY config config
RUN mix do deps.get, deps.compile

COPY lib lib
COPY priv priv

RUN mix do compile, release

FROM alpine:3.13 AS app

RUN apk add --no-cache openssl ncurses-libs

WORKDIR /app

RUN chown nobody:nobody /app
USER nobody:nobody
COPY --from=build --chown=nobody:nobody /app/_build/prod/rel/nous ./
ENV HOME=/app

CMD ["bin/nous",  "start"]