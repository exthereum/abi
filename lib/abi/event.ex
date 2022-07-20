defmodule ABI.Event do
  @doc ~S"""
  Decodes an event, including handling parsing out data from topics.

  ## Examples

      iex> "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034241540000000000000000000000000000000000000000000000000000000000"
      ...> |> Base.decode16!(case: :lower)
      ...> |> ABI.Event.decode_event(
      ...>      [] |> Enum.map(&Base.decode16!(&1, case: :lower)),
      ...>      %ABI.FunctionSelector{
      ...>        function: "Transfer",
      ...>        types: [
      ...>          %{type: :address, name: "from", indexed: true},
      ...>          %{type: :address, name: "to", indexed: true},
      ...>          %{type: {:uint, 256}, name: "amount"},
      ...>        ]
      ...>      }
      ...>    )
      ""
  """
  def decode_event(data, topics, function_selector) do
  end

  @doc ~S"""
  Decodes an event, including handling parsing out data from topics.

  ## Examples

      iex> "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034241540000000000000000000000000000000000000000000000000000000000"
      ...> |> Base.decode16!(case: :lower)
      ...> |> ABI.Event.event_topic(
      ...>      [] |> Enum.map(&Base.decode16!(&1, case: :lower)),
      ...>      %ABI.FunctionSelector{
      ...>        function: "Transfer",
      ...>        types: [
      ...>          %{type: :address, name: "from", indexed: true},
      ...>          %{type: :address, name: "to", indexed: true},
      ...>          %{type: {:uint, 256}, name: "amount"},
      ...>        ]
      ...>      }
      ...>    )
      ""
  """
  def event_topic(function_selector) do
  end

  # iex> ABI.decode_event(
  #     ...>   "Transfer(address indexed from,address indexed to,uint value)",
  #     ...>   [
  #     ...>     "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef" |> Base.decode16!(case: :lower),
  #     ...>     "0x000000000000000000000000b2b7c1795f19fbc28fda77a95e59edbb8b3709c8" |> Base.decode16!(case: :lower),
  #     ...>     "0x0000000000000000000000007795126b3ae468f44c901287de98594198ce38ea" |> Base.decode16!(case: :lower)
  #     ...>   ],
  #     ...>   "0x00000000000000000000000000000000000000000000000000000004a817c800" |> Base.decode16!(case: :lower)
  #     ...> )
  #     {"Transfer", %{
  #       to: Base.decode16!("0xb2b7c1795f19fbc28fda77a95e59edbb8b3709c8", case: :lower)
  #       from: Base.decode16!("0x7795126b3ae468f44c901287de98594198ce38ea", case: :lower)
  #       amount: 20000000000
  #     }}
end
