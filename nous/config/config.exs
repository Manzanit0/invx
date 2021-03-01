import Config

config :nous,
  ecto_repos: [Nous.Repo]

config :nous, NousWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "swDhEVjKPmeKBRDCn2Xj7PBgHoZeJEZVOkRAILcQS5pff52eAyzP7EDU06v5N3YE",
  render_errors: [view: NousWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Nous.PubSub,
  live_view: [signing_salt: "ODMGxJHd"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :json_library, Jason

import_config "#{config_env()}.exs"
