defmodule Nous.Receipts.ReceiptsParser do
  require Logger

  @doc """
  Reduces a tesseract table assuming it's an invoice table to a map mapping
  price by name.

  It asumes the format coming from Tesseract: {{row, column}, text}
  """
  @spec table_result_to_price_map(Nous.Tesseract.table()) :: map
  def table_result_to_price_map(map) do
    Enum.reduce(map, %{}, fn {{row, col}, text}, acc ->
      # col == 1 is the concept, col == 2 is the price
      text =
        if col > 1,
          do: text |> unwrap_text() |> maybe_parse_float(),
          else: unwrap_text(text)

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

  defp maybe_parse_float("," <> text), do: maybe_parse_float("0," <> text)
  defp maybe_parse_float("." <> text), do: maybe_parse_float("0." <> text)

  defp maybe_parse_float(text) do
    curated = String.replace(text, ",", ".")

    # Extract floating point numbers from the string.
    number =
      case Regex.scan(~r/\-*\d+\.\d+/, curated) do
        [[number] | _] -> number
        _ -> curated
      end

    case Float.parse(number) do
      :error -> number
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
