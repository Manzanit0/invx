FROM bitwalker/alpine-elixir-phoenix:1.13.1

WORKDIR /app

COPY mix.exs .
COPY mix.lock .

CMD mix do deps.get, deps.compile, phx.server
