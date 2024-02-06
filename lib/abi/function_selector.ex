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
          | {:tuple, [type]}
          | {:struct, String.t(), [type], [String.t()]}

  @type t :: %__MODULE__{
          function: String.t(),
          types: [type],
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
          {:uint, 256},
          :bool
        ]
      }

      iex> ABI.FunctionSelector.decode("(uint256,bool)")
      %ABI.FunctionSelector{
        function: nil,
        types: [
          {:uint, 256},
          :bool
        ]
      }

      iex> ABI.FunctionSelector.decode("growl(uint,address,string[])")
      %ABI.FunctionSelector{
        function: "growl",
        types: [
          {:uint, 256},
          :address,
          {:array, :string}
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
          {:array, :address}
        ]
      }

      iex> ABI.FunctionSelector.decode("paw(string[2])")
      %ABI.FunctionSelector{
        function: "paw",
        types: [
          {:array, :string, 2}
        ]
      }

      iex> ABI.FunctionSelector.decode("scram(uint256[])")
      %ABI.FunctionSelector{
        function: "scram",
        types: [
          {:array, {:uint, 256}}
        ]
      }

      iex> ABI.FunctionSelector.decode("shake((string))")
      %ABI.FunctionSelector{
        function: "shake",
        types: [
          {:tuple, [:string]}
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
    types
  end

  @doc """
  Parse a function selector, e.g. from an abi.json file.

  ## Examples

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "a", "type" => "uint96", "internalType" => "uint96"}]})
      %ABI.FunctionSelector{function: "fun", types: [uint: 96], returns: nil}

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "tuple", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"name" => "b", "type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{function: "fun", types: [{:tuple, [{:uint, 256}, :address, :bytes]}, {:uint, 256}], returns: :bytes}

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "struct Contract.Struct", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"name" => "b", "type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{function: "fun", types: [{:struct, "Contract.Struct", [{:uint, 256}, :address, :bytes], ["a", "b", "c"]}, {:uint, 256}], returns: :bytes}

      iex> ABI.FunctionSelector.parse_specification_item(%{"type" => "function", "name" => "fun", "inputs" => [%{"name" => "s", "type" => "tuple", "internalType" => "struct Contract.Struct", "components" => [%{"name" => "a", "type" => "uint256", "internalType" => "uint256"},%{"type" => "address", "internalType" => "address"},%{"name" => "c", "type" => "bytes", "internalType" => "bytes"}]},%{"name" => "d", "type" => "uint256", "internalType" => "uint256"}],"outputs" => [%{"name" => "", "type" => "bytes", "internalType" => "bytes"}],"stateMutability" => "nonpayable"})
      %ABI.FunctionSelector{function: "fun", types: [{:struct, "Contract.Struct", [{:uint, 256}, :address, :bytes], ["a", "var1", "c"]}, {:uint, 256}], returns: :bytes}
  """
  def parse_specification_item(%{"type" => "function"} = item) do
    input_types = Enum.map(Map.get(item, "inputs", []), &parse_specification_type/1)
    output_types = Enum.map(Map.get(item, "outputs", []), &parse_specification_type/1)

    %ABI.FunctionSelector{
      function: Map.get(item, "name", nil),
      types: input_types,
      returns: List.first(output_types)
    }
  end

  def parse_specification_item(%{"type" => "fallback"}) do
    %ABI.FunctionSelector{
      function: nil,
      types: [],
      returns: nil
    }
  end

  def parse_specification_item(_), do: nil

  defp parse_specification_type(%{"type" => "tuple", "internalType" => "struct " <> struct_name, "components" => components}) do
    {:struct, struct_name, Enum.map(components, &parse_specification_type/1), Enum.with_index(components, fn x, i -> x["name"] || "var#{i}" end)}
  end

  defp parse_specification_type(%{"type" => "tuple", "components" => components}) do
    {:tuple, Enum.map(components, &parse_specification_type/1)}
  end

  defp parse_specification_type(%{"type" => type}), do: decode_type(type)

  @doc """
  Decodes the given type-string as a single type.

  ## Examples

      iex> ABI.FunctionSelector.decode_type("uint256")
      {:uint, 256}

      iex> ABI.FunctionSelector.decode_type("(bool,address)")
      {:tuple, [:bool, :address]}

      iex> ABI.FunctionSelector.decode_type("address[][3]")
      {:array, {:array, :address}, 3}
  """
  def decode_type(single_type) do
    ABI.Parser.parse!(single_type, as: :type)
  end

  @doc """
  Encodes a function call signature.

  ## Examples

      iex> ABI.FunctionSelector.encode(%ABI.FunctionSelector{
      ...>   function: "bark",
      ...>   types: [
      ...>     {:uint, 256},
      ...>     :bool,
      ...>     {:array, :string},
      ...>     {:array, :string, 3},
      ...>     {:tuple, [{:uint, 256}, :bool]}
      ...>   ]
      ...> })
      "bark(uint256,bool,string[],string[3],(uint256,bool))"
  """
  def encode(function_selector) do
    types = get_types(function_selector) |> Enum.join(",")

    "#{function_selector.function}(#{types})"
  end

  defp get_types(function_selector) do
    for type <- function_selector.types do
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
    encoded_types = Enum.map(types, &get_type/1)
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
