defmodule Nous.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      Nous.Repo,
      NousWeb.Telemetry,
      {Phoenix.PubSub, name: Nous.PubSub},
      NousWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Nous.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    NousWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
