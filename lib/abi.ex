defmodule ABI do
  @moduledoc """
  Documentation for ABI, the function interface language for Solidity.
  Generally, the ABI describes how to take binary Ethereum and transform
  it to or from types that Solidity understands.
  """

  @doc """
  Encodes the given data into the function signature or tuple signature.

  In place of a signature, you can also pass one of the `ABI.FunctionSelector` structs returned from `parse_specification/1`.

  ## Examples

      iex> ABI.encode("(uint256)", [{10}])
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000000a"

      iex> ABI.encode("baz(uint,address)", [50, <<1::160>>])
      ...> |> Base.encode16(case: :lower)
      "a291add600000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000001"

      iex> ABI.encode("price(string)", ["BAT"])
      ...> |> Base.encode16(case: :lower)
      "fe2c6198000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034241540000000000000000000000000000000000000000000000000000000000"

      iex> ABI.encode("baz(uint8)", [9999])
      ** (RuntimeError) Data overflow encoding uint, data `9999` cannot fit in 8 bits

      iex> ABI.encode("(uint,address)", [{50, <<1::160>>}])
      ...> |> Base.encode16(case: :lower)
      "00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000001"

      iex> ABI.encode("(string)", [{"Ether Token"}])
      ...> |> Base.encode16(case: :lower)
      "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000"

      iex> ABI.encode("((uint256,uint256),string)", [{{0x11, 0x22}, "Ether Token"}])
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000"

      iex> ABI.encode("((uint256,(uint256,uint256)),string)", [{{0x11, {0x22, 0x33}}, "Ether Token"}])
      ...> |> Base.encode16(case: :lower)
      "0000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000"

      iex> ABI.encode("(string)", [{String.duplicate("1234567890", 10)}])
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000643132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393000000000000000000000000000000000000000000000000000000000"

      iex> File.read!("priv/dog.abi.json")
      ...> |> Jason.decode!
      ...> |> ABI.parse_specification
      ...> |> Enum.find(&(&1.function == "bark")) # bark(address,bool)
      ...> |> ABI.encode([<<1::160>>, true])
      ...> |> Base.encode16(case: :lower)
      "b85d0bd200000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001"
  """
  def encode(function_signature, data) when is_binary(function_signature) do
    encode(ABI.Parser.parse!(function_signature), data)
  end

  def encode(%ABI.FunctionSelector{} = function_selector, data) do
    ABI.TypeEncoder.encode(data, function_selector)
  end

  @doc """
  Decodes the given data based on the function or tuple
  signature.

  In place of a signature, you can also pass one of the `ABI.FunctionSelector` structs returned from `parse_specification/1`.

  ## Examples

      iex> ABI.decode("baz(uint,address)", "00000000000000000000000000000000000000000000000000000000000000320000000000000000000000000000000000000000000000000000000000000001" |> Base.decode16!(case: :lower))
      [50, <<1::160>>]

      iex> ABI.decode("(address[])", "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000" |> Base.decode16!(case: :lower))
      [[]]

      iex> ABI.decode("(uint256)", "000000000000000000000000000000000000000000000000000000000000000a" |> Base.decode16!(case: :lower))
      [10]

      iex> ABI.decode("(string)", "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000" |> Base.decode16!(case: :lower))
      ["Ether Token"]

      iex> ABI.decode("((uint256,uint256),string)", "000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000" |> Base.decode16!(case: :lower))
      [{0x11, 0x22}, "Ether Token"]

      iex> ABI.decode("((uint256,(uint256,uint256)),string)", "0000000000000000000000000000000000000000000000000000000000000011000000000000000000000000000000000000000000000000000000000000002200000000000000000000000000000000000000000000000000000000000000330000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000b457468657220546f6b656e000000000000000000000000000000000000000000" |> Base.decode16!(case: :lower))
      [{0x11, {0x22, 0x33}}, "Ether Token"]

      iex> File.read!("priv/dog.abi.json")
      ...> |> Jason.decode!
      ...> |> ABI.parse_specification
      ...> |> Enum.find(&(&1.function == "bark")) # bark(address,bool)
      ...> |> ABI.decode("00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001" |> Base.decode16!(case: :lower))
      [<<1::160>>, true]
  """
  def decode(function_signature, data) when is_binary(function_signature) do
    decode(ABI.FunctionSelector.decode(function_signature), data)
  end

  def decode(%ABI.FunctionSelector{} = function_selector, data) do
    [res] = ABI.TypeDecoder.decode_raw(data, [%{type: {:tuple, function_selector.types}}])
    Tuple.to_list(res)
  end

  @doc """
  Decodes an event, including indexed and non-indexed data.

  ## Examples

      iex> ABI.decode_event(
      ...>   "Transfer(address indexed from, address indexed to, uint256 amount)",
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef],
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ]
      ...> )
      {:ok,
        "Transfer", %{
          "amount" => 20000000000,
          "from" => ~h[0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
          "to" => ~h[0x7795126b3ae468f44c901287de98594198ce38ea]
      }}

      iex> ABI.decode_event(
      ...>   "Transfer(address indexed from, address indexed to, uint256 amount)",
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ],
      ...>   check_event_signature: false
      ...> )
      {:ok,
        "Transfer", %{
          "amount" => 20000000000,
          "from" => ~h[0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
          "to" => ~h[0x7795126b3ae468f44c901287de98594198ce38ea]
      }}

      iex> ABI.decode_event(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   },
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef],
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ]
      ...> )
      {:ok,
        "Transfer", %{
          "amount" => 20000000000,
          "from" => ~h[0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
          "to" => ~h[0x7795126b3ae468f44c901287de98594198ce38ea]
      }}
  """
  def decode_event(function_signature, data, topics, opts \\ [])

  def decode_event(function_signature, data, topics, opts) when is_binary(function_signature) do
    decode_event(ABI.FunctionSelector.decode(function_signature), data, topics, opts)
  end

  def decode_event(%ABI.FunctionSelector{} = function_selector, data, topics, opts) do
    ABI.Event.decode_event(data, topics, function_selector, opts)
  end

  @doc """
  Returns the signature for an event.

  ## Examples

      iex> ABI.event_signature("Transfer(address indexed from, address indexed to, uint256 amount)")
      ...> |> Base.encode16(case: :lower)
      "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  """
  def event_signature(function_signature) when is_binary(function_signature) do
    event_signature(ABI.FunctionSelector.decode(function_signature))
  end

  def event_signature(%ABI.FunctionSelector{} = function_selector) do
    ABI.Event.event_signature(function_selector)
  end

  @doc """
  Parses the given ABI specification document into an array of `ABI.FunctionSelector`s.

  Non-function entries (e.g. constructors) in the ABI specification are skipped. Fallback function entries are accepted.

  This function can be used in combination with a JSON parser, e.g. [`Jason`](https://hex.pm/packages/jason), to parse ABI specification JSON files.

  ## Examples

      iex> File.read!("priv/dog.abi.json")
      ...> |> Jason.decode!
      ...> |> ABI.parse_specification
      [%ABI.FunctionSelector{function: "bark", function_type: :function, state_mutability: :nonpayable, returns: [], types: [%{name: "at", type: :address}, %{name: "loudly", type: :bool}]},
       %ABI.FunctionSelector{function: "rollover", function_type: :function, state_mutability: :nonpayable, returns: [%{name: "is_a_good_boy", type: :bool}], types: []}]

      iex> [%{
      ...>   "constant" => true,
      ...>   "inputs" => [
      ...>     %{"name" => "at", "type" => "address"},
      ...>     %{"name" => "loudly", "type" => "bool"}
      ...>   ],
      ...>   "name" => "bark",
      ...>   "outputs" => [],
      ...>   "payable" => false,
      ...>   "stateMutability" => "pure",
      ...>   "type" => "function"
      ...> }]
      ...> |> ABI.parse_specification
      [
        %ABI.FunctionSelector{function: "bark", function_type: :function, state_mutability: :pure, returns: [], types: [
          %{type: :address, name: "at"},
          %{type: :bool, name: "loudly"}
        ]}
      ]

      iex> [%{
      ...>   "inputs" => [
      ...>      %{"name" => "_numProposals", "type" => "uint8"}
      ...>   ],
      ...>   "payable" => false,
      ...>   "stateMutability" => "nonpayable",
      ...>   "type" => "constructor"
      ...> }]
      ...> |> ABI.parse_specification
      [%ABI.FunctionSelector{function: nil, function_type: :constructor, state_mutability: :nonpayable, types: [%{name: "_numProposals", type: {:uint, 8}}], returns: nil}]

      iex> ABI.decode("(string)", "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000643132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393031323334353637383930313233343536373839303132333435363738393000000000000000000000000000000000000000000000000000000000" |> Base.decode16!(case: :lower))
      [String.duplicate("1234567890", 10)]

      iex> [%{
      ...>   "payable" => false,
      ...>   "stateMutability" => "nonpayable",
      ...>   "type" => "fallback"
      ...> }]
      ...> |> ABI.parse_specification
      [%ABI.FunctionSelector{function: nil, function_type: :fallback, state_mutability: :nonpayable, returns: nil, types: []}]
  """
  def parse_specification(doc) do
    doc
    |> Enum.map(&ABI.FunctionSelector.parse_specification_item/1)
    |> Enum.filter(& &1)
  end
end
