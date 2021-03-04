defmodule NousWeb.ReceiptsController do
  use NousWeb, :controller

  require Logger

  alias Nous.Tesseract
  alias Nous.ReceiptsParser

  def parse_receipt(conn, %{"receipt" => %{path: path}}) do
    Logger.info("Attempting to parse receipt")

    client =
      AWS.Client.create(
        System.fetch_env!("AWS_ACCESS_KEY_ID"),
        System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
        System.fetch_env!("AWS_REGION")
      )

    with {:file, {:ok, content}} <- {:file, File.read(path)},
         {:analyse, {:ok, result}} <-
           {:analyse, Tesseract.analyse(content, client, encode: true, type: :table)} do
      [table | _] = Tesseract.parse_table_result(result)

      mapped_prices = ReceiptsParser.table_result_to_price_map(table)
      count = mapped_prices |> Map.values() |> length()
      total_price = mapped_prices |> Map.values() |> Enum.filter(&is_float/1) |> Enum.sum()

      json(conn, %{items: mapped_prices, items_count: count, total_price: total_price})
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
