defmodule Nous.Tesseract do
  @moduledoc """
  Block documentation: https://docs.aws.amazon.com/textract/latest/dg/API_Block.html

  Find the key/value phrases documentation: https://docs.aws.amazon.com/textract/latest/dg/how-it-works-kvp.html

  A KEY object contains information about the key for linked text. For
  example, Name:. A KEY block has two relationship lists. A relationship of
  type VALUE is a list that contains the ID of the VALUE block that's
  associated with the key. A relationship of type CHILD is a list of IDs
  for the WORD blocks that make up the text of the key.

  A VALUE object contains information about the text that's associated with a
  key. In the preceding example, Ana Carolina is the value for the key Name:. A
  VALUE block has a relationship with a list of CHILD blocks that identify WORD
  blocks. Each WORD block contains one of the words that make up the text of
  the value. A VALUE object can also contain information about selected
  elements. For more information, see Selection Elements.
  """

  require Logger

  @type analyse_opts :: [encode: boolean(), type: :form | :table]

  @type textract_result :: %{optional(String.t()) => any}

  @type form_result :: %{optional(String.t()) => String.t()}

  @type table_row_index :: integer
  @type table_col_index :: integer
  @type table_result :: %{{table_row_index, table_col_index} => String.t()}

  @type analyse_result :: {:ok, form_result | table_result} | {:error, any}

  @spec analyse(binary, AWS.Client.t(), analyse_opts()) :: analyse_result
  def analyse(file_content, client, opts) do
    Logger.info("Starting to analyse document via Tesseract. Options: #{inspect(opts)}")

    bytes =
      if Keyword.get(opts, :encode, true), do: Base.encode64(file_content), else: file_content

    feature_types =
      case Keyword.get(opts, :type, :form) do
        :form ->
          ["FORMS"]

        :table ->
          ["TABLES"]

        other ->
          raise """
          analyse/3 only accepts the values :form and :table for analysing a
          document, but it has received: #{inspect(other)}.
          """
      end

    payload = %{
      "FeatureTypes" => feature_types,
      "Document" => %{
        "Bytes" => bytes
      }
    }

    with {:ok, response_body, _http_response} <- AWS.Textract.analyze_document(client, payload) do
      Logger.info("Successfully analysed document.")
      {:ok, response_body}
    else
      {:error, {:unexpected_response, %{status_code: 400} = response}} ->
        Logger.warn("Failed with status code 400. Response= #{inspect(response)}")
        {:error, :throttling_exception}

      other ->
        Logger.warn("Unknown error: #{inspect(other)}")
        other
    end
  end

  @spec parse_form_result(textract_result) :: form_result
  def parse_form_result(%{"Blocks" => blocks}), do: parse_form_result(blocks)

  def parse_form_result(blocks) do
    %{blocks: block_map, keys: key_map} =
      Enum.reduce(
        blocks,
        %{blocks: %{}, keys: %{}},
        fn block, acc ->
          acc = %{acc | blocks: Map.put(acc.blocks, block["Id"], block)}

          if block["BlockType"] == "KEY_VALUE_SET" &&
               Enum.member?(block["EntityTypes"] || [], "KEY") do
            %{acc | keys: Map.put(acc.keys, block["Id"], block)}
          else
            acc
          end
        end
      )

    for {block_id, _} <- key_map, into: %{} do
      relationships =
        block_map
        |> Map.get(block_id, %{})
        |> Map.get("Relationships", [])

      keyword_ids =
        relationships
        |> Enum.find(%{}, &(&1["Type"] == "CHILD"))
        |> Map.get("Ids", [])

      key_phrase =
        keyword_ids
        |> Enum.reduce("", fn id, acc -> "#{acc} #{block_map[id]["Text"]}" end)
        |> String.trim()

      value_ids =
        relationships
        |> Enum.find(%{}, &(&1["Type"] == "VALUE"))
        |> Map.get("Ids", [])

      value_phrase =
        block_map
        |> Map.get(List.first(value_ids), %{})
        |> Map.get("Relationships", [])
        |> Enum.find(%{}, &(&1["Type"] == "CHILD"))
        |> Map.get("Ids", [])
        |> Enum.reduce("", fn id, acc -> "#{acc} #{block_map[id]["Text"]}" end)
        |> String.trim()

      {key_phrase, value_phrase}
    end
  end

  @spec parse_table_result(textract_result) :: list(table_result)
  def parse_table_result(%{"Blocks" => blocks}), do: parse_table_result(blocks)

  def parse_table_result(blocks) do
    # first sort out blocks into a map and enumerate table blocks.
    %{blocks: block_map, tables: tables} =
      Enum.reduce(
        blocks,
        %{blocks: %{}, tables: []},
        fn block, acc ->
          acc = %{acc | blocks: Map.put(acc.blocks, block["Id"], block)}

          if block["BlockType"] == "TABLE" do
            %{acc | tables: [block | acc.tables]}
          else
            acc
          end
        end
      )

    # Now traverse each table, and each table's children (rows), and sort them
    # into a map of type {row, column} => value
    for table <- tables do
      for relationship <- table["Relationships"],
          child_id <- relationship["Ids"],
          relationship["Type"] == "CHILD",
          into: %{} do
        cell = block_map[child_id]

        if cell["BlockType"] == "CELL" do
          row_index = cell["RowIndex"]
          col_index = cell["ColumnIndex"]

          {{row_index, col_index}, get_text(cell, block_map)}
        end
      end
    end
  end

  defp get_text(%{"Relationships" => relationships}, block_map) do
    for relationship <- relationships,
        child_id <- relationship["Ids"],
        relationship["Type"] == "CHILD",
        into: "" do
      word = block_map[child_id]

      cond do
        word["BlockType"] == "WORD" ->
          "#{word["Text"]} "

        word["BlockType"] == "SELECTION_ELEMENT" and word["SelectionStatus"] == "SELECTED" ->
          "X "

        true ->
          "N/a"
      end
    end
  end

  defp get_text(_other, _block_map), do: "N/a"
end
