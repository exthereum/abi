defmodule ABI.TypeEncoder do
  @moduledoc """
  `ABI.TypeEncoder` is responsible for encoding types to the format
  expected by Solidity. We generally take a function selector and an
  array of data and encode that array according to the specification.
  """

  @doc """
  Encodes the given data based on the function selector.

  ## Examples

      iex> [69, true]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: "baz",
      ...>        types: [
      ...>          %{type: {:uint, 32}},
      ...>          %{type: :bool}
      ...>        ],
      ...>        returns: :bool
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "cdcd77c000000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001"

      iex> ["BAT"]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: "price",
      ...>        types: [
      ...>          %{type: :string}
      ...>        ],
      ...>        returns: {:uint, 256}
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "fe2c6198000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000034241540000000000000000000000000000000000000000000000000000000000"


      iex> [Base.decode16!("ffffffffffffffffffffffffffffffffffffffff", case: :lower)]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: "price",
      ...>        types: [
      ...>          %{type: :address}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "aea91078000000000000000000000000ffffffffffffffffffffffffffffffffffffffff"

      iex> [1]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: "price",
      ...>        types: [
      ...>          %{type: :address}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "aea910780000000000000000000000000000000000000000000000000000000000000001"

      iex> ["hello world"]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: :string},
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000"

      iex> [{{0x11, 0x22}, "hello world"}]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: {:tuple, [
      ...>            %{type: {:tuple, [%{type: {:uint, 256}},%{type: {:uint, 256}}]}},
      ...>            %{type: :string},
      ...>          ]}}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000220000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000b68656c6c6f20776f726c64000000000000000000000000000000000000000000"

      iex> [{"awesome", true}]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: {:tuple, [%{type: :string}, %{type: :bool}]}}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000007617765736f6d6500000000000000000000000000000000000000000000000000"

      iex> [{17, true, <<32, 64>>}]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: {:tuple, [%{type: {:uint, 32}}, %{type: :bool}, %{type: {:bytes, 2}}]}}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000012040000000000000000000000000000000000000000000000000000000000000"

      iex> [[17, 1]]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: "baz",
      ...>        types: [
      ...>          %{type: {:array, {:uint, 32}, 2}}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "3d0ec53300000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000001"

      iex> [[17, 1], true]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: {:array, {:uint, 32}, 2}},
      ...>          %{type: :bool}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000001100000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000001"

      iex> [[17, 1]]
      ...> |> ABI.TypeEncoder.encode(
      ...>      %ABI.FunctionSelector{
      ...>        function: nil,
      ...>        types: [
      ...>          %{type: {:array, {:uint, 32}}}
      ...>        ]
      ...>      }
      ...>    )
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000110000000000000000000000000000000000000000000000000000000000000001"

      iex> [
      ...>   <<1::160>>,
      ...>   <<2::160>>,
      ...>   <<3::256>>,
      ...>   {
      ...>     4,
      ...>     <<5::160>>,
      ...>     <<6>>,
      ...>     <<7::512>>,
      ...>     8
      ...>   },
      ...>   9,
      ...>   <<0xa::256>>,
      ...>   <<0xb::256>>
      ...> ]
      ...> |> ABI.TypeEncoder.encode(
      ...>   %ABI.FunctionSelector{
      ...>     function: "test",
      ...>     function_type: :function,
      ...>     state_mutability: :nonpayable,
      ...>     types: [
      ...>       %{name: "a", type: :address},
      ...>       %{name: "b", type: :address},
      ...>       %{name: "c", type: {:bytes, 32}},
      ...>       %{
      ...>         name: "d",
      ...>         type:
      ...>           {:tuple,
      ...>            [
      ...>              %{name: "e", type: {:uint, 96}},
      ...>              %{name: "f", type: :address},
      ...>              %{name: "g", type: :bytes},
      ...>              %{name: "h", type: :bytes},
      ...>              %{name: "i", type: {:uint, 256}}
      ...>            ]}
      ...>       },
      ...>       %{name: "j", type: {:uint, 8}},
      ...>       %{name: "k", type: {:bytes, 32}},
      ...>       %{name: "l", type: {:bytes, 32}}
      ...>     ],
      ...>     returns: [%{name: "", type: :bytes}]
      ...>   }
      ...> )
      ...> |> Base.encode16(case: :lower)
      "19c9d90a00000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000300000000000000000000000000000000000000000000000000000000000000e00000000000000000000000000000000000000000000000000000000000000009000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000b0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000010600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000007"
  """
  def encode(data, function_selector) do
    encode_method_id(function_selector) <> do_encode_data(data, function_selector)
  end

  defp do_encode_data(data, %ABI.FunctionSelector{function: nil}=function_selector) do
    encode_raw(data, function_selector.types)
  end

  defp do_encode_data(data, %ABI.FunctionSelector{}=function_selector) do
    encode_raw([List.to_tuple(data)], [%{type: {:tuple, function_selector.types}}])
  end

  @doc """
  Simiar to `ABI.TypeEncoder.encode/2` except we accept
  an array of types instead of a function selector. We also
  do not pre-pend the method id.

  ## Examples

      iex> [{"awesome", true}]
      ...> |> ABI.TypeEncoder.encode_raw([%{type: {:tuple, [%{type: :string}, %{type: :bool}]}}])
      ...> |> Base.encode16(case: :lower)
      "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000000000000007617765736f6d6500000000000000000000000000000000000000000000000000"
  """
  def encode_raw(data, types) do
    do_encode(types, data, [])
  end

  @spec encode_method_id(%ABI.FunctionSelector{}) :: binary()
  defp encode_method_id(%ABI.FunctionSelector{function: nil}), do: ""

  defp encode_method_id(function_selector) do
    # Encode selector e.g. "baz(uint32,bool)" and take keccak
    kec =
      function_selector
      |> ABI.FunctionSelector.encode()
      |> ABI.Math.kec()

    # Take first four bytes
    <<init::binary-size(4), _rest::binary>> = kec

    # That's our method id
    init
  end

  @spec do_encode([ABI.FunctionSelector.type()], [any()], [binary()]) :: binary()
  defp do_encode([], _, acc), do: :erlang.iolist_to_binary(Enum.reverse(acc))

  defp do_encode([type | remaining_types], data, acc) do
    {encoded, remaining_data} = encode_type(type.type, data)

    do_encode(remaining_types, remaining_data, [encoded | acc])
  end

  @spec encode_type(ABI.FunctionSelector.type(), [any()]) :: {binary(), [any()]}
  defp encode_type({:uint, size}, [data | rest]) do
    {encode_uint(data, size), rest}
  end

  defp encode_type(:address, data), do: encode_type({:uint, 160}, data)

  defp encode_type(:bool, [data | rest]) do
    value =
      case data do
        true -> encode_uint(1, 8)
        false -> encode_uint(0, 8)
        _ -> raise "Invalid data for bool: #{data}"
      end

    {value, rest}
  end

  defp encode_type(:string, [data | rest]) do
    {encode_uint(byte_size(data), 256) <> encode_bytes(data), rest}
  end

  defp encode_type(:bytes, [data | rest]) do
    {encode_uint(byte_size(data), 256) <> encode_bytes(data), rest}
  end

  defp encode_type({:bytes, size}, [data | rest])
       when is_binary(data) and byte_size(data) <= size do
    {encode_bytes(data), rest}
  end

  defp encode_type({:bytes, size}, [data | _]) when is_binary(data) do
    raise "size mismatch for bytes#{size}: #{inspect(data)}"
  end

  defp encode_type({:bytes, size}, [data | _]) do
    raise "wrong datatype for bytes#{size}: #{inspect(data)}"
  end

  defp encode_type({:tuple, types}, [data | rest]) do
    # all head items are 32 bytes in length and there will be exactly
    # `count(types)` of them, so the tail starts at `32 * count(types)`.
    # Note: `count(types)` accounts for inlined tuples.
    tail_start = count(types) * 32

    {head, tail, [], _} =
      Enum.reduce(types, {<<>>, <<>>, data_to_list(types, data), tail_start}, fn argument_type,
                                                                               {head, tail, data,
                                                                                tail_position} ->
        type = argument_type.type
        {el, rest} = encode_type(type, data)

        if ABI.FunctionSelector.is_dynamic?(type) do
          # If we're a dynamic type, just encoded the length to head and the element to body
          {head <> encode_uint(tail_position, 256), tail <> el, rest,
           tail_position + byte_size(el)}
        else
          # If we're a static type, simply encode the el to the head
          {head <> el, tail, rest, tail_position}
        end
      end)

    {head <> tail, rest}
  end

  defp encode_type({:array, type, element_count}, [data | rest]) do
    repeated_type = if element_count == 0 do
      []
    else
       Enum.map(1..element_count, fn _ -> %{type: type} end)
    end

    encode_type({:tuple, repeated_type}, [data |> List.to_tuple() | rest])
  end

  defp encode_type({:array, type}, [data | _rest] = all_data) do
    element_count = Enum.count(data)

    encoded_uint = encode_uint(element_count, 256)
    {encoded_array, rest} = encode_type({:array, type, element_count}, all_data)

    {encoded_uint <> encoded_array, rest}
  end

  defp encode_type(els, _) do
    raise "Unsupported encoding type: #{inspect(els)}"
  end

  def encode_bytes(bytes) do
    bytes |> pad(byte_size(bytes), :right)
  end

  # Note, we'll accept a binary or an integer here, so long as the
  # binary is not longer than our allowed data size
  defp encode_uint(data, size_in_bits) when rem(size_in_bits, 8) == 0 do
    size_in_bytes = (size_in_bits / 8) |> round
    bin = maybe_encode_unsigned(data)

    if byte_size(bin) > size_in_bytes,
      do:
        raise(
          "Data overflow encoding uint, data `#{data}` cannot fit in #{size_in_bytes * 8} bits"
        )

    bin |> pad(size_in_bytes, :left)
  end

  defp pad(bin, size_in_bytes, direction) do
    # TODO: Create `left_pad` repo, err, add to `ABI.Math`
    total_size = size_in_bytes + ABI.Math.mod(32 - ABI.Math.mod(size_in_bytes, 32), 32)

    padding_size_bits = (total_size - byte_size(bin)) * 8
    padding = <<0::size(padding_size_bits)>>

    case direction do
      :left -> padding <> bin
      :right -> bin <> padding
    end
  end

  # Returns the total number of static types, accounting for inlined tuples
  defp count(sub_types) do
    sub_types
    |> Enum.map(&do_count/1)
    |> Enum.sum()
  end

  defp do_count(%{type: t={:tuple, sub_types}}) do
    if ABI.FunctionSelector.is_dynamic?(t) do
      1
    else
      sub_types
      |> Enum.map(&do_count/1)
      |> Enum.sum()
    end
  end
  defp do_count(_), do: 1

  defp data_to_list(_types, data) when is_list(data), do: data
  defp data_to_list(_types, data) when is_tuple(data), do: Tuple.to_list(data)
  defp data_to_list(types, data) when is_map(data) do
    Enum.map(types, fn type ->
      if type[:name] do
        atom_name = String.to_atom(Macro.underscore(type[:name]))
        if data[atom_name] do
          data[atom_name]
        else
          raise "Cannot find key `#{atom_name}` for type `#{inspect(type)}`\n\n\tin data:\n\n\t#{inspect(data)}"
        end
      else
        raise "Cannot decode struct with map when no name given in type `#{inspect(type)}`\n\n\tfor data:\n\n\t#{inspect(data)}"
      end
    end)
  end

  @spec maybe_encode_unsigned(binary() | integer()) :: binary()
  defp maybe_encode_unsigned(bin) when is_binary(bin), do: bin
  defp maybe_encode_unsigned(int) when is_integer(int), do: :binary.encode_unsigned(int)
end
