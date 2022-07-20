defmodule ABI.Event do
  @doc ~S"""
  Decodes an event, including handling parsing out data from topics.

  ## Examples

      iex> "00000000000000000000000000000000000000000000000000000004a817c800"
      ...> |> Base.decode16!(case: :lower)
      ...> |> ABI.Event.decode_event(
      ...>   [
      ...>     "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" |> Base.decode16!(case: :lower),
      ...>     "000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8" |> Base.decode16!(case: :lower),
      ...>     "0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea" |> Base.decode16!(case: :lower)
      ...>   ],
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   })
      {"Transfer",
       %{
         "amount" => 20_000_000_000,
         "from" => [
           <<252, 55, 141, 170, 149, 43, 167, 241, 99, 196, 161, 22, 40, 245, 90, 77, 245, 35, 179, 239>>
         ],
         "to" => [
           <<178, 183, 193, 121, 95, 25, 251, 194, 143, 218, 119, 169, 94, 89, 237, 187, 139, 55, 9, 200>>
         ]
       }}
  """
  def decode_event(data, topics, function_selector) do
    # First, split the types into indexed and not indexed
    {indexed_types, non_indexed_types} =
      Enum.split_with(function_selector.types, fn t -> Map.get(t, :indexed) end)

    indexed_data =
      indexed_types
      |> Enum.zip(topics)
      |> Enum.map(fn {type, topic} ->
        {type.name, ABI.TypeDecoder.decode_raw(topic, [type])}
      end)
      |> Enum.into(%{})

    non_indexed_data =
      data
      |> ABI.TypeDecoder.decode_raw(non_indexed_types)
      |> Enum.zip(non_indexed_types)
      |> Enum.map(fn {res, %{name: name}} -> {name, res} end)
      |> Enum.into(%{})

    {function_selector.function, Map.merge(indexed_data, non_indexed_data)}
  end

  @doc ~S"""
  Returns the topic of an event, i.e. the first item that appears
  in an Ethereum log for this event.

  ## Examples

      iex> ABI.Event.event_topic(
      ...>   %ABI.FunctionSelector{
      ...>     function: "Transfer",
      ...>     types: [
      ...>       %{type: :address, name: "from", indexed: true},
      ...>       %{type: :address, name: "to", indexed: true},
      ...>       %{type: {:uint, 256}, name: "amount"},
      ...>     ]
      ...>   }
      ...> )
      ...> |> Base.encode16(case: :lower)
      "ddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef"
  """
  def event_topic(function_selector) do
    function_selector
    |> ABI.FunctionSelector.encode()
    |> ABI.Math.kec()
  end
end
