defmodule NousWeb.Auth do
  import Plug.Conn
  require Logger

  def init([]), do: false

  # If the request is already authorised, then simple continue.
  def call(%{assigns: %{current_user: _}} = conn, _opts), do: conn

  def call(conn, _opts) do
    token =
      conn
      |> get_req_header("authorization")
      |> List.first()

    if authorised?(token) do
      assign(conn, :current_user, token)
    else
      conn
      |> send_resp(401, "Unauthorized")
      |> halt()
    end
  end

  defp authorised?(token) do
    Enum.member?(get_auth_secrets(), token)
  end

  defp get_auth_secrets do
    Application.get_env(:nous, __MODULE__, [])
    |> Keyword.get(:secrets)
    |> String.split(",")
    |> Enum.map(&String.trim/1)
  end
end
