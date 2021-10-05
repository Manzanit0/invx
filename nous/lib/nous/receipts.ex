defmodule Nous.Receipts do
  alias Nous.Tesseract
  alias Nous.Receipts.ReceiptsParser

  def create_receipt do
  end

  def analyse_receipt(content) do
    client = new_aws_client()

    with {:ok, result} <- Tesseract.analyse(content, client, encode: true, type: :table) do
      [table | _] = Tesseract.parse_table_result(result)

      mapped_prices = ReceiptsParser.table_result_to_price_map(table)
      count = mapped_prices |> Map.values() |> length()
      total_price = mapped_prices |> Map.values() |> Enum.filter(&is_float/1) |> Enum.sum()

      {:ok, %{items: mapped_prices, items_count: count, total_price: total_price}}
    end
  end

  defp new_aws_client do
    AWS.Client.create(
      Application.get_env(:aws, :access_key_id),
      Application.get_env(:aws, :secret_access_key),
      Application.get_env(:aws, :region)
    )
  end
end
