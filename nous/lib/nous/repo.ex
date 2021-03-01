defmodule Nous.Repo do
  use Ecto.Repo,
    otp_app: :nous,
    adapter: Ecto.Adapters.Postgres
end
