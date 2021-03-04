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

        mapped_prices = Nous.ReceiptsParser.table_result_to_price_map(table)

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
end
