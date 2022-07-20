defmodule ABI.FunctionSelector do
  @moduledoc """
  Module to help parse the ABI function signatures, e.g.
  `my_function(uint64, string[])`.
  """

  require Integer

  @type type ::
          {:uint, integer()}
          | :bool
          | :bytes
          | :string
          | :address
          | {:array, type}
          | {:array, type, non_neg_integer}
          | {:tuple, [argument_type]}

  @type argument_type ::
          %{:type => type, optional(:name) => String.t(), optional(:indexed) => boolean()}

  @type t :: %__MODULE__{
          function: String.t(),
          types: [argument_type],
          returns: type
        }

  defstruct [:function, :types, :returns]

  @doc """
  Decodes a function selector to a struct.

  ## Examples

      iex> ABI.FunctionSelector.decode("bark(uint256,bool)")
      %ABI.FunctionSelector{
        function: "bark",
        types: [
          %{type: {:uint, 256}},
          %{type: :bool}
        ]
      }

      iex> ABI.FunctionSelector.decode("bark(uint256 name, bool loud)")
      %ABI.FunctionSelector{
        function: "bark",
        types: [
          %{type: {:uint, 256}, name: "name"},
          %{type: :bool, name: "loud"}
        ]
      }

      iex> ABI.FunctionSelector.decode("bark(uint256 name,bool indexed loud)")
      %ABI.FunctionSelector{
        function: "bark",
        types: [
          %{type: {:uint, 256}, name: "name"},
          %{type: :bool, name: "loud", indexed: true}
        ]
      }

      iex> ABI.FunctionSelector.decode("(uint256,bool)")
      %ABI.FunctionSelector{
        function: nil,
        types: [
          %{type: {:uint, 256}},
          %{type: :bool}
        ]
      }

      iex> ABI.FunctionSelector.decode("growl(uint,address,string[])")
      %ABI.FunctionSelector{
        function: "growl",
        types: [
          %{type: {:uint, 256}},
          %{type: :address},
          %{type: {:array, :string}}
        ]
      }

      iex> ABI.FunctionSelector.decode("rollover()")
      %ABI.FunctionSelector{
        function: "rollover",
        types: []
      }

      iex> ABI.FunctionSelector.decode("do_playDead3()")
      %ABI.FunctionSelector{
        function: "do_playDead3",
        types: []
      }

      iex> ABI.FunctionSelector.decode("pet(address[])")
      %ABI.FunctionSelector{
        function: "pet",
        types: [
          %{type: {:array, :address}}
        ]
      }

      iex> ABI.FunctionSelector.decode("paw(string[2])")
      %ABI.FunctionSelector{
        function: "paw",
        types: [
          %{type: {:array, :string, 2}}
        ]
      }

      iex> ABI.FunctionSelector.decode("scram(uint256[])")
      %ABI.FunctionSelector{
        function: "scram",
        types: [
          %{type: {:array, {:uint, 256}}}
        ]
      }

      iex> ABI.FunctionSelector.decode("shake((string))")
      %ABI.FunctionSelector{
        function: "shake",
        types: [
          %{type: {:tuple, [%{type: :string}]}}
        ]
      }
  """
  def decode(signature) do
    ABI.Parser.parse!(signature, as: :selector)
  end

  @doc """
  Decodes the given type-string as a simple array of types.

  ## Examples

      iex> ABI.FunctionSelector.decode_raw("string,uint256")
      [:string, {:uint, 256}]

      iex> ABI.FunctionSelector.decode_raw("")
      []
  """
  def decode_raw(type_string) do
    {:tuple, types} = decode_type("(#{type_string})")
    Enum.map(types, fn argument_type -> argument_type.type end)
  end

  @doc """
  Parse a function selector, e.g. from an abi.json file.

  ## Examples

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "a", "type" => "uint96", "internalType" => "uint96"}]})
      %ABI.FunctionSelector{
        function: "fun",
        types: [%{type: {:uint, 96}, name: "a"}],
        returns: nil
      }

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "tuple", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"name" => "b", "type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{
        function: "fun",
        types: [
          %{
            type:
              {:tuple, [
                %{type: {:uint, 256}, name: "a"},
                %{type: :address, name: "b"},
                %{type: :bytes, name: "c"}
              ]},
              name: "s"
          }, %{
            type: {:uint, 256},
            name: "d"
          }
        ],
        returns: [%{name: "", type: :bytes}],
      }

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "struct Contract.Struct", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"name" => "b", "type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{
        function: "fun",
        types: [
          %{
            type:
              {:tuple, [
                %{type: {:uint, 256}, name: "a"},
                %{type: :address, name: "b"},
                %{type: :bytes, name: "c"}
              ]},
              name: "s"
          }, %{
            type: {:uint, 256},
            name: "d"
          }
        ],
        returns: [%{name: "", type: :bytes}],
      }

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "struct Contract.Struct", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{
        function: "fun",
        types: [
          %{
            type:
              {:tuple, [
                %{type: {:uint, 256}, name: "a"},
                %{type: :address},
                %{type: :bytes, name: "c"}
              ]},
              name: "s"
          }, %{
            type: {:uint, 256},
            name: "d"
          }
        ],
        returns: [%{name: "", type: :bytes}],
      }

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "fallback"})
      %ABI.FunctionSelector{
        function: nil,
        types: [],
        returns: nil
      }

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "receive"})
      %ABI.FunctionSelector{
        function: nil,
        types: [],
        returns: nil
      }
  """
  def parse_specification_item(%{"type" => _function_type} = item) do
    input_types = Enum.map(Map.get(item, "inputs", []), &parse_specification_type/1)
    output_types = if Map.has_key?(item, "outputs"), do: Enum.map(item["outputs"], &parse_specification_type/1), else: nil

    %ABI.FunctionSelector{
      function: Map.get(item, "name", nil),
      types: input_types,
      returns: output_types
    }
  end

  defp parse_specification_type(%{"type" => "tuple", "name" => name, "components" => components}) do
    %{name: name, type: {:tuple, Enum.map(components, &parse_specification_type/1)}}
  end

  defp parse_specification_type(%{"type" => "tuple", "components" => components}) do
    %{type: {:tuple, Enum.map(components, &parse_specification_type/1)}}
  end

  defp parse_specification_type(%{"type" => type, "name" => name}) do
    %{type: decode_type(type), name: name}
  end

  defp parse_specification_type(%{"type" => type}) do
    %{type: decode_type(type)}
  end

  @doc """
  Decodes the given type-string as a single type.

  ## Examples

      iex> ABI.FunctionSelector.decode_type("uint256")
      {:uint, 256}

      iex> ABI.FunctionSelector.decode_type("(bool,address)")
      {:tuple, [%{type: :bool}, %{type: :address}]}

      iex> ABI.FunctionSelector.decode_type("address[][3]")
      {:array, {:array, :address}, 3}
  """
  def decode_type(single_type) do
    ABI.Parser.parse!(single_type, as: :type)
  end

  @doc """
  Encodes a function call signature.

  ## Example

      iex> ABI.FunctionSelector.encode(%ABI.FunctionSelector{
      ...>   function: "bark",
      ...>   types: [
      ...>     %{type: {:uint, 256}},
      ...>     %{type: :bool},
      ...>     %{type: {:array, :string}},
      ...>     %{type: {:array, :string, 3}},
      ...>     %{type: {:tuple, [%{type: {:uint, 256}}, %{type: :bool}]}}
      ...>   ]
      ...> })
      "bark(uint256,bool,string[],string[3],(uint256,bool))"
  """
  def encode(function_selector) do
    types = get_types(function_selector) |> Enum.join(",")

    "#{function_selector.function}(#{types})"
  end

  defp get_types(function_selector) do
    for %{type: type} <- function_selector.types do
      get_type(type)
    end
  end

  defp get_type(nil), do: nil
  defp get_type({:int, size}), do: "int#{size}"
  defp get_type({:uint, size}), do: "uint#{size}"
  defp get_type(:address), do: "address"
  defp get_type(:bool), do: "bool"
  defp get_type({:fixed, element_count, precision}), do: "fixed#{element_count}x#{precision}"
  defp get_type({:ufixed, element_count, precision}), do: "ufixed#{element_count}x#{precision}"
  defp get_type({:bytes, size}), do: "bytes#{size}"
  defp get_type(:function), do: "function"

  defp get_type({:array, type, element_count}), do: "#{get_type(type)}[#{element_count}]"

  defp get_type(:bytes), do: "bytes"
  defp get_type(:string), do: "string"
  defp get_type({:array, type}), do: "#{get_type(type)}[]"

  defp get_type({:tuple, types}) do
    encoded_types = Enum.map(types, fn argument_type -> get_type(argument_type.type) end)
    "(#{Enum.join(encoded_types, ",")})"
  end

  defp get_type({:struct, _name, types, _names}) do
    encoded_types = Enum.map(types, &get_type/1)
    "(#{Enum.join(encoded_types, ",")})"
  end

  defp get_type(els), do: raise("Unsupported type: #{inspect(els)}")

  @doc false
  @spec is_dynamic?(ABI.FunctionSelector.type()) :: boolean
  def is_dynamic?(:bytes), do: true
  def is_dynamic?(:string), do: true
  def is_dynamic?({:array, _type}), do: true
  def is_dynamic?({:array, type, len}) when len > 0, do: is_dynamic?(type)
  def is_dynamic?({:tuple, types}), do: Enum.any?(types, &is_dynamic?/1)
  def is_dynamic?({:struct, _name, types, _names}), do: Enum.any?(types, &is_dynamic?/1)
  def is_dynamic?(_), do: false
end
