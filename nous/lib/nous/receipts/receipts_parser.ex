defmodule Nous.Receipts.ReceiptsParser do
  require Logger

  @doc """
  Reduces a tesseract table assuming it's an invoice table to a map mapping
  price by name.

  It asumes the format coming from Tesseract: {{row, column}, text}
  """
  @spec table_result_to_price_map(Nous.Tesseract.table()) :: map
  def table_result_to_price_map(map) do
    map = if get_columns_amount(map) == 2, do: map, else: reduce_multicolumn_map_to_2_columns(map)

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

  # get the number of columns in the receipt table.  Since the map has the
  # format: {row, column} => value, it can be infered from the maximum value of
  # "column".
  defp get_columns_amount(map) do
    Enum.reduce(map, 0, fn
      {{_, col}, _}, acc when col > acc -> col
      _, acc -> acc
    end)
  end

  # Many receipts have multiple columns: the item, a description, an amount,
  # another description, etc. In these scenarios we want to reduce the map to a
  # simple {description, total} tuple. That's what this function does.
  defp reduce_multicolumn_map_to_2_columns(map) do
    header = for {{row, _}, value} when row == 1 <- map, reduce: [], do: (acc -> [value | acc])
    product_name_position = 1 + Enum.find_index(header, &item_name?/1)
    product_price_position = 1 + Enum.find_index(header, &item_price?/1)

    for {{row, col}, value}
        when col == product_name_position or col == product_price_position <-
          map,
        reduce: %{},
        do: (acc -> Map.put(acc, {row, col}, value))
  end

  defp item_name?(name) do
    name
    |> String.downcase()
    |> String.trim()
    |> case do
      "producto" -> true
      "produto" -> true
      "product" -> true
      "servicio" -> true
      "service" -> true
      "articulo" -> true
      "description" -> true
      "descripcion" -> true
      "descripción" -> true
      _ -> false
    end
  end

  defp item_price?(name) do
    name
    |> String.downcase()
    |> String.trim()
    |> case do
      # total first, in case there's both total and price
      "total" -> true
      "importe" -> true
      "price" -> true
      "precio" -> true
      _ -> false
    end
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
