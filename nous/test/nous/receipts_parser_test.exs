defmodule NousTest.ReceiptsParserTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureLog

  alias Nous.Receipts.ReceiptsParser

  describe "receipts parser" do
    test "receipts with numbers as item descriptions" do
      table = %{
        {1, 1} => "kg",
        {1, 2} => "EURO/k9",
        {1, 3} => "EURO",
        {2, 1} => "1.715",
        {2, 2} => "13.25",
        {2, 3} => "9.47",
        {3, 1} => ".575",
        {3, 2} => "12.50",
        {3, 3} => "7.19",
        {4, 1} => ".235",
        {4, 2} => "3.50",
        {4, 3} => "0.82",
        {5, 1} => ".100",
        {5, 2} => "4.60",
        {5, 3} => "0.46",
        {6, 1} => ".120",
        {6, 2} => "5.15",
        {6, 3} => "0.62",
        {7, 1} => ".530",
        {7, 2} => "13.00",
        {7, 3} => "6.89",
        {8, 1} => ".105",
        {8, 2} => "40.00",
        {8, 3} => "4.20",
        {9, 1} => ".605",
        {9, 2} => "12.50",
        {9, 3} => "7.56 "
      }

      result = ReceiptsParser.table_result_to_price_map(table)

      assert result == %{
               ".100" => 0.46,
               ".105" => 4.2,
               ".120" => 0.62,
               ".235" => 0.82,
               ".530" => 6.89,
               ".575" => 7.19,
               ".605" => 7.56,
               "1.715" => 9.47,
               "EURO" => "kg"
             }
    end

    test "receipts with multiple columns are reduced to two: item and price" do
      table = %{
        {1, 1} => "PRODUCTO",
        {1, 2} => "€/L",
        {1, 3} => "LITROS",
        {1, 4} => "IMPORTE",
        {2, 1} => "EFITED 95",
        {2, 2} => "1,789",
        {2, 3} => "22,36",
        {2, 4} => "40,00 SOLRED "
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"IMPORTE" => "PRODUCTO", "EFITED 95" => 40.00}

      table = %{
        {1, 1} => "Und",
        {1, 2} => "Articulo",
        {1, 3} => "Precio",
        {1, 4} => "Total",
        {2, 1} => "2,00",
        {2, 2} => "HAMB. TERNERA",
        {2, 3} => "7,90",
        {2, 4} => "15,80",
        {3, 1} => "1,00",
        {3, 2} => "CROQUETAS JAMON",
        {3, 3} => "9,00",
        {3, 4} => "9,00 "
      }

      result = ReceiptsParser.table_result_to_price_map(table)

      assert result == %{
               "HAMB. TERNERA" => 15.80,
               "CROQUETAS JAMON" => 9.00,
               "Total" => "Articulo"
             }
    end

    test "prices with dots are parsed" do
      table = %{
        {2, 1} => "tomatoes",
        {2, 2} => "3.45 "
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes" => 3.45}
    end

    test "prices with commas are parsed" do
      table = %{
        {2, 1} => "tomatoes",
        {2, 2} => "3,45 "
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes" => 3.45}
    end

    test "prices without leading zero are parsed" do
      table = %{
        {2, 1} => "tomatoes",
        {2, 2} => ",45 "
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes" => 0.45}
    end

    test "prices with trailing letters are parsed" do
      table = %{
        {2, 1} => "tomatoes",
        {2, 2} => "3.45 C"
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes" => 3.45}
    end

    test "prices with leading letters are parsed" do
      table = %{
        {2, 1} => "tomatoes",
        {2, 2} => "N/a3.45 C"
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes" => 3.45}
    end

    test "names with numbers are allowed" do
      table = %{
        {2, 1} => "tomatoes x1.99",
        {2, 2} => "3.45"
      }

      result = ReceiptsParser.table_result_to_price_map(table)
      assert result == %{"tomatoes x1.99" => 3.45}
    end

    test "a complete ticket (Carrefour)" do
      carrefour_analysis = %{
        {51, 2} => "2.71",
        {23, 2} => "2.81",
        {18, 2} => "2.60",
        {2, 1} => "SUAVIZANTE 78LAV A531",
        {2, 2} => "3.45",
        {39, 2} => "1,45",
        {47, 1} => "AÑOJO FILE 1 A CP",
        {26, 2} => "2.50",
        {26, 1} => "ALCAPARRAS",
        {31, 1} => "CIRUELA AMARILLA",
        {29, 1} => "DESCUENTO EN 2 UNIDAD CL57",
        {37, 2} => "0,69",
        {45, 2} => "1.16",
        {25, 1} => "ACELGA MANOJO 1 KG",
        {6, 1} => "ACEITUNAS NEGRAS 200 3 X ( 1.50 )",
        {46, 1} => "PANES ESPECIALES",
        {31, 2} => "1,05",
        {20, 1} => "QUESO FETA BIO 180G",
        {15, 2} => "2.15",
        {21, 1} => "QUESO FETA GRIEGA",
        {28, 2} => "2,50",
        {5, 1} => "AC.NEG.ARAG.ECO220",
        {50, 2} => "15.03",
        {33, 1} => "HIERBABUENA MANOJO",
        {45, 1} => "PANECILLO VARIADO 4 x ( 0,29 )",
        {7, 1} => "ARROZ SUNDARI 1KG",
        {19, 2} => "4,30",
        {3, 1} => "SUAVIZANTE FRESCOR A531",
        {24, 2} => "7,54",
        {9, 2} => "1,60",
        {56, 2} => "0,16",
        {17, 2} => "1,99",
        {6, 2} => "4,50",
        {8, 2} => "2,39",
        {21, 2} => "2.95",
        {52, 2} => "7.81",
        {11, 2} => "2,18",
        {40, 1} => "TOMATE COCKTAIL 225G",
        {27, 1} => "CANONIGO 125G CRF",
        {53, 2} => "3.90",
        {7, 2} => "2,69",
        {35, 1} => "JUDIA PERONA",
        {9, 1} => "KETCHUP HEINZ 340G A609",
        {20, 2} => "1,99",
        {40, 2} => "1.79",
        {16, 2} => "1.99",
        {55, 1} => "TROCEADA GUISAR",
        {38, 2} => "1.19",
        {29, 2} => "-0,63",
        {47, 2} => "1,87",
        {54, 1} => "TROCEADA GUISAR",
        {28, 1} => "CEBOLLA CARREFOUR CL57 2x( 1,25 )",
        {16, 1} => "JAMON COCIDO ARGAL",
        {32, 1} => "COLIFLOR PIEZA",
        {56, 1} => "BOLSA P 50-70%RECI 2x( 0,08 )",
        {23, 1} => "ESTORNINO",
        {57, 1} => "SUJETADOR MATERNIDAD 0029",
        {11, 1} => "TOMATE NATURAL ENTER 2 x ( 1,09 )",
        {38, 1} => "PAK CHOI 300GR",
        {12, 1} => "TOMATE TROCEADO 4 x ( 0,85 )",
        {34, 2} => "1.03",
        {25, 2} => "2,25",
        {55, 2} => "4.00",
        {36, 2} => "2.89",
        {4, 1} => "DESCUENTO EN 2 UNIDAD A531",
        {39, 1} => "PUERRO MANOJO 3 U",
        {44, 2} => "1,30",
        {5, 2} => "2,15",
        {43, 2} => "1.99",
        {46, 2} => "2,50",
        {1, 2} => "25.40",
        {42, 1} => "TOMATE ROSA",
        {4, 2} => "-1,82",
        {10, 2} => "1,80",
        {30, 2} => "1,39",
        {32, 2} => "1.85",
        {36, 1} => "MAIZ FRESCO BANDEJ",
        {24, 1} => "SALMON PIEZAS CYO",
        {34, 1} => "HINOJO",
        {22, 2} => "3,99",
        {54, 2} => "4.01",
        {43, 1} => "ZANAHORIA CRF BIO",
        {10, 1} => "SALSA VERDE HERDEZ",
        {8, 1} => "GARAM MASALA",
        {57, 2} => "7,99",
        {37, 1} => "NARANJA CYO",
        {49, 1} => "MUSLO POLLO CAMPERO",
        {22, 1} => "SALOMON SALVAJE",
        {14, 1} => "FETA SIMONS BARIL",
        {41, 1} => "TOMATE MINI CHERRY",
        {51, 1} => "SOLOMILLO DE POLLO",
        {53, 1} => "TORREZNO SORIA",
        {30, 1} => "CILANTRO MANOJO 100G",
        {42, 2} => "2,19",
        {44, 1} => "CHAPATA",
        {14, 2} => "2.15",
        {48, 1} => "ENTRECOT VACN PIEDRA",
        {1, 1} => "PAÑALES SENSITIVE",
        {3, 2} => "3.85",
        {15, 1} => "FLAN DE QUESO X 4",
        {13, 2} => "1.81",
        {50, 1} => "RABO DE VACUNO",
        {41, 2} => "1,99",
        {17, 1} => "LECHE FRESCA BIO",
        {33, 2} => "1,29",
        {35, 2} => "3.33",
        {19, 1} => "MOUSSE AZUCARADO X 4 2x ( 2,15 )",
        {52, 1} => "SOLOMILLO VACUNO",
        {13, 1} => "CINTAS BACON TARRA",
        {18, 1} => "MANTEQUILLA SIN SAL",
        {49, 2} => "5,98",
        {12, 2} => "3,40",
        {48, 2} => "15,54",
        {27, 2} => "1,11 "
      }

      expected = %{
        "CIRUELA AMARILLA" => 1.05,
        "SUJETADOR MATERNIDAD 0029" => 7.99,
        "PUERRO MANOJO 3 U" => 1.45,
        "AC.NEG.ARAG.ECO220" => 2.15,
        "MUSLO POLLO CAMPERO" => 5.98,
        "SOLOMILLO VACUNO" => 7.81,
        "ALCAPARRAS" => 2.5,
        "QUESO FETA BIO 180G" => 1.99,
        "TORREZNO SORIA" => 3.9,
        "ENTRECOT VACN PIEDRA" => 15.54,
        "CEBOLLA CARREFOUR CL57 2x( 1,25 )" => 2.5,
        "TOMATE ROSA" => 2.19,
        "NARANJA CYO" => 0.69,
        "HIERBABUENA MANOJO" => 1.29,
        "PANES ESPECIALES" => 2.5,
        "CILANTRO MANOJO 100G" => 1.39,
        "SUAVIZANTE FRESCOR A531" => 3.85,
        "CHAPATA" => 1.3,
        "TOMATE COCKTAIL 225G" => 1.79,
        "CANONIGO 125G CRF" => 1.11,
        "PAÑALES SENSITIVE" => 25.4,
        "BOLSA P 50-70%RECI 2x( 0,08 )" => 0.16,
        "PAK CHOI 300GR" => 1.19,
        "FLAN DE QUESO X 4" => 2.15,
        "SOLOMILLO DE POLLO" => 2.71,
        "JAMON COCIDO ARGAL" => 1.99,
        "DESCUENTO EN 2 UNIDAD A531" => -1.82,
        "SUAVIZANTE 78LAV A531" => 3.45,
        "RABO DE VACUNO" => 15.03,
        "TOMATE MINI CHERRY" => 1.99,
        "ARROZ SUNDARI 1KG" => 2.69,
        "SALMON PIEZAS CYO" => 7.54,
        "MANTEQUILLA SIN SAL" => 2.6,
        "GARAM MASALA" => 2.39,
        "SALSA VERDE HERDEZ" => 1.8,
        "HINOJO" => 1.03,
        "JUDIA PERONA" => 3.33,
        "TOMATE TROCEADO 4 x ( 0,85 )" => 3.4,
        "TROCEADA GUISAR" => 4.01,
        "MOUSSE AZUCARADO X 4 2x ( 2,15 )" => 4.3,
        "MAIZ FRESCO BANDEJ" => 2.89,
        "PANECILLO VARIADO 4 x ( 0,29 )" => 1.16,
        "DESCUENTO EN 2 UNIDAD CL57" => -0.63,
        "QUESO FETA GRIEGA" => 2.95,
        "TOMATE NATURAL ENTER 2 x ( 1,09 )" => 2.18,
        "ACELGA MANOJO 1 KG" => 2.25,
        "ACEITUNAS NEGRAS 200 3 X ( 1.50 )" => 4.5,
        "FETA SIMONS BARIL" => 2.15,
        "CINTAS BACON TARRA" => 1.81,
        "ZANAHORIA CRF BIO" => 1.99,
        "LECHE FRESCA BIO" => 1.99,
        "AÑOJO FILE 1 A CP" => 1.87,
        "COLIFLOR PIEZA" => 1.85,
        "KETCHUP HEINZ 340G A609" => 1.6,
        "ESTORNINO" => 2.81,
        "SALOMON SALVAJE" => 3.99
      }

      result = ReceiptsParser.table_result_to_price_map(carrefour_analysis)
      assert result == expected
    end

    test "another complete ticket (LIDL)" do
      lidl_analysis = %{
        {18, 2} => "7.99 8",
        {2, 1} => "Milbona/Leche fresca ent",
        {2, 2} => "0,78 A",
        {6, 1} => "Tomate cherry rama",
        {15, 2} => "0,85 A",
        {5, 1} => "Pimiento rojo kg 0,370 kg x 1.89 EUR/kg",
        {7, 1} => "Dto. Lidl Plus",
        {3, 1} => "Puerro 500g",
        {17, 2} => "1,99 8",
        {6, 2} => "N/a1,99 A",
        {8, 2} => "0,95 A",
        {11, 2} => "N/aX X 0,10 C",
        {7, 2} => "-0.50",
        # this will trigger warning
        {9, 1} => "0,476 kg x 1,99 EUR/kg",
        {9, 2} => "N/a",
        {16, 2} => "1,49 B",
        {16, 1} => "Bulbos de primaver",
        {11, 1} => "Lidl/Bolsa pequeña",
        {12, 1} => "Bacalao punto sal",
        {4, 1} => "Judia plana",
        {5, 2} => "0,70 A",
        # this will trigger warning
        {1, 1} => "N/a",
        {1, 2} => "EUR",
        {4, 2} => "2,19 A",
        {10, 2} => "N/a3,98 B 1.99",
        {10, 1} => "Acentino/Vinagre balsámi x1,99 Dto. Lidl Plus",
        {8, 1} => "Manzana Reineta",
        {14, 1} => "Cebolla 1 Kg",
        {14, 2} => "1,19 A",
        {3, 2} => "1,69 A",
        {15, 1} => "Lima pack 4",
        {17, 1} => "Ciclamen",
        # this will trigger warning
        {13, 1} => "0,500 kg x 11.29 EUR/kg",
        {13, 2} => "N/a",
        {18, 1} => "Cúrcuma",
        {12, 2} => "5,65 8 "
      }

      expected = %{
        "Acentino/Vinagre balsámi x1,99 Dto. Lidl Plus" => 3.98,
        "Bacalao punto sal" => 5.65,
        "Bulbos de primaver" => 1.49,
        "Cebolla 1 Kg" => 1.19,
        "Ciclamen" => 1.99,
        "Cúrcuma" => 7.99,
        "Dto. Lidl Plus" => -0.5,
        "Judia plana" => 2.19,
        "Lidl/Bolsa pequeña" => 0.1,
        "Lima pack 4" => 0.85,
        "Manzana Reineta" => 0.95,
        "Milbona/Leche fresca ent" => 0.78,
        "Pimiento rojo kg 0,370 kg x 1.89 EUR/kg" => 0.7,
        "Puerro 500g" => 1.69,
        "Tomate cherry rama" => 1.99
      }

      assert capture_log(fn ->
               result = ReceiptsParser.table_result_to_price_map(lidl_analysis)
               assert result == expected
             end) =~ "received unknown element"
    end
  end
end
