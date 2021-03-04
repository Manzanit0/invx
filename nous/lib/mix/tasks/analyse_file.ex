defmodule Mix.Tasks.AnalyseFile do
  @moduledoc "Printed when the user requests `mix help echo`"
  @shortdoc "Analyses a file through AWS Textract"

  use Mix.Task
  require Logger
  alias Nous.Tesseract

  @syntax_colours [number: :yellow, atom: :cyan, string: :green, boolean: :magenta, nil: :magenta]

  @impl Mix.Task
  def run(args) do
    client =
      AWS.Client.create(
        System.fetch_env!("AWS_ACCESS_KEY_ID"),
        System.fetch_env!("AWS_SECRET_ACCESS_KEY"),
        System.fetch_env!("AWS_REGION")
      )

    for filename <- args do
      IO.puts("\nFile: #{filename}")

      with {:ok, content} <- File.read(filename),
           {:ok, result} <- Tesseract.analyse(content, client, encode: true, type: :table) do
        [table | _] = Tesseract.parse_table_result(result)

        IO.inspect(table,
          syntax_colors: @syntax_colours,
          pretty: true,
          label: :raw_analysis_result
        )

        mapped_prices = table_result_to_price_map(table)

        IO.inspect(mapped_prices,
          syntax_colors: @syntax_colours,
          pretty: true,
          label: :parsed_prices_from_result
        )

        sum =
          mapped_prices
          |> Map.values()
          |> Enum.filter(&is_float/1)
          |> Enum.sum()

        IO.puts(IO.ANSI.red() <> "\nPrices Sum: #{sum}")
      else
        err -> IO.warn("Error happened: #{inspect(err)}")
      end
    end
  end

  @doc """
  Reduces a tesseract table assuming it's an invoice table to a map mapping
  price by name.

  It asumes the format coming from Tesseract: {{row, column}, text}
  """
  @spec table_result_to_price_map(Nous.Tesseract.table()) :: map
  def table_result_to_price_map(map) do
    Enum.reduce(map, %{}, fn {{row, _col}, text}, acc ->
      text = text |> unwrap_text() |> maybe_parse_float()

      cond do
        text == "N/a" ->
          acc

        Map.has_key?(acc, row) ->
          Map.put(acc, row, [text | acc[row]])

        true ->
          Map.put(acc, row, [text])
      end
    end)
    |> Map.values()
    |> Enum.reduce(%{}, &price_reductor/2)
  end

  defp unwrap_text(text) when is_binary(text), do: text
  defp unwrap_text([text | _t]), do: text

  defp maybe_parse_float("," <> text), do: maybe_parse_float("0" <> text)

  defp maybe_parse_float(text) do
    case Float.parse(text) do
      :error -> text
      {f, _} -> f
    end
  end

  # Makes sure to map the element to the price and not viceversa
  defp price_reductor([first, last], acc) when is_float(first), do: Map.put(acc, last, first)

  defp price_reductor([first, last], acc), do: Map.put(acc, first, last)

  defp price_reductor(other, acc) do
    Logger.warn("received unknown element in price_reductor/2: #{inspect(other)}")
    acc
  end
end
