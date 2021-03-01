defmodule NousWeb.Router do
  use NousWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", NousWeb do
    pipe_through :api
  end

  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: NousWeb.Telemetry
    end
  end
end
