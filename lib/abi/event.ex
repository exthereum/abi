defmodule ABI.Event do
  @doc ~S"""
  Decodes an event, including handling parsing out data from topics.

  ## Examples

      iex> ABI.Event.decode_event(
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef],
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ],
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   })
      {:ok,
        "Transfer", %{
          "amount" => 20000000000,
          "from" => ~h[0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
          "to" => ~h[0x7795126b3ae468f44c901287de98594198ce38ea]
      }}

      iex> ABI.Event.decode_event(
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0x0000000000000000000000000000000000000000000000000000000000000001],
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ],
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   })
      {:error, "Mismatched event signature topic[0], expected=DDF252AD1BE2C89B69C2B068FC378DAA952BA7F163C4A11628F55A4DF523B3EF, got=0000000000000000000000000000000000000000000000000000000000000001"}

      iex> ABI.Event.decode_event(
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ],
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   })
      {:error, "Invalid topics length (got=2, expected=3), consider toggling `check_event_signature`"}

      iex> ABI.Event.decode_event(
      ...>   ~h[0x00000000000000000000000000000000000000000000000000000004a817c800],
      ...>   [
      ...>     ~h[0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
      ...>     ~h[0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea]
      ...>   ],
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   },
      ...>   check_event_signature: false
      ...> )
      {:ok,
        "Transfer", %{
          "amount" => 20000000000,
          "from" => ~h[0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8],
          "to" => ~h[0x7795126b3ae468f44c901287de98594198ce38ea]
      }}
  """
  def decode_event(data, topics, function_selector, opts \\ []) do
    check_event_signature = Keyword.get(opts, :check_event_signature, true)

    # First, split the types into indexed and not indexed
    {indexed_types, non_indexed_types} =
      Enum.split_with(function_selector.types, fn t -> Map.get(t, :indexed) end)

    indexed_types_full = if check_event_signature do
      [%{type: {:bytes, 32}, name: "__abi__topic"} | indexed_types]
    else
      indexed_types
    end

    if Enum.count(indexed_types_full) != Enum.count(topics) do
      {:error, "Invalid topics length (got=#{Enum.count(topics)}, expected=#{Enum.count(indexed_types_full)}), consider toggling `check_event_signature`"}
    else
      indexed_data =
        indexed_types_full
        |> Enum.zip(topics)
        |> Enum.map(fn {type, topic} ->
          [value] = ABI.TypeDecoder.decode_raw(topic, [type])
          {type.name, value}
        end)
        |> Enum.into(%{})

      [non_indexed_data] = ABI.TypeDecoder.decode_raw(data, [%{type: {:tuple, non_indexed_types}}])

      non_indexed_data_map =
        non_indexed_data
        |> Tuple.to_list()
        |> Enum.zip(non_indexed_types)
        |> Enum.map(fn {res, %{name: name}} -> {name, res} end)
        |> Enum.into(%{})

      indexed_data_res = if check_event_signature do
        {event_signature, res} = Map.pop(indexed_data, "__abi__topic")

        if event_signature == event_signature(function_selector) do
          {:ok, res}
        else
          {:error, "Mismatched event signature topic[0], expected=#{Base.encode16(event_signature(function_selector))}, got=#{Base.encode16(event_signature)}"}
        end
      else
        {:ok, indexed_data}
      end

      with {:ok, indexed_data_full} <- indexed_data_res do
        {:ok, function_selector.function, Map.merge(indexed_data_full, non_indexed_data_map)}
      end
    end
  end

  @doc ~S"""
  Returns the signature of an event, i.e. the first item that appears
  in an Ethereum log for this event.

  ## Examples

      iex> ABI.Event.event_signature(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   }
      ...> )
      ...> |> to_hex()
      "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  """
  def event_signature(function_selector) do
    function_selector
    |> ABI.FunctionSelector.encode()
    |> ABI.Math.kec()
  end

  @doc ~S"""
  Returns the canonical form of this event topic. Pass in `indexed: true`
  to include "indexed" keywords.

  ## Examples

      iex> ABI.Event.canonical(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   }
      ...> )
      "Transfer(address,address,uint256)"

      iex> ABI.Event.canonical(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   },
      ...>   names: true
      ...> )
      "Transfer(address from,address to,uint256 amount)"

      iex> ABI.Event.canonical(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   },
      ...>   indexed: true
      ...> )
      "Transfer(address indexed,address indexed,uint256)"

      iex> ABI.Event.canonical(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   },
      ...>   indexed: true,
      ...>   names: true
      ...> )
      "Transfer(address indexed from,address indexed to,uint256 amount)"
  """
  def canonical(function_selector, opts \\ []) do
    indexed = Keyword.get(opts, :indexed, false)
    names = Keyword.get(opts, :names, false)

    ABI.FunctionSelector.encode(function_selector, indexed, names)
  end
end
