defmodule NousWeb.ReceiptsController do
  use NousWeb, :controller

  require Logger
  alias Nous.Receipts

  def parse_receipt(conn, %{"receipt" => %{path: path}}) do
    Logger.info("Attempting to parse receipt")

    with {:file, {:ok, content}} <- {:file, File.read(path)},
         {:analyse, {:ok, res}} <- {:analyse, Receipts.analyse_receipt(content)} do
      json(conn, res)
    else
      {:file, {:error, err}} ->
        json(conn, %{error: "error reading file: #{inspect(err)}"})

      {:analyse, {:error, err}} ->
        json(conn, %{error: "error analysing file: #{inspect(err)}"})

      other ->
        json(conn, %{error: "#{inspect(other)}"})
    end
  end
end
