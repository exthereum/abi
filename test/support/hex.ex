defmodule ABI.Hex do
  @moduledoc """
  This is Signet.Hex, but copied just for test-cases.
  """

  defmodule HexError do
    defexception message: "invalid hex"
  end

  @type t :: binary()

  defmacro __using__(_opts) do
    quote do
      require ABI.Hex
      alias ABI.Hex

      import ABI.Hex,
        only: [sigil_h: 2, hex!: 1, to_hex: 1, from_hex: 1, from_hex!: 1]
    end
  end

  @doc ~S"""
  Handles the sigil `~h` for list of words.

  Parses a hex string at compile-time.

  ## Examples

      iex> use ABI.Hex
      iex> ~h[0x22]
      <<0x22>>

      iex> use ABI.Hex
      iex> ~h[0x2244]
      <<0x22, 0x44>>
  """
  defmacro sigil_h(term, modifiers)

  defmacro sigil_h({:<<>>, _meta, [string]}, _modifiers = []) when is_binary(string) do
    hex_str = :elixir_interpolation.unescape_string(string)

    ABI.Hex.decode_hex!(hex_str)
  end

  @doc ~S"""
  Similar non-sigil compile-time hex parser.

  ## Examples

      iex> use ABI.Hex
      iex> hex!("0x22")
      <<0x22>>

      iex> use ABI.Hex
      iex> hex!("0x2244")
      <<0x22, 0x44>>
  """
  defmacro hex!(hex_str) when is_binary(hex_str) do
    ABI.Hex.decode_hex!(hex_str)
  end

  @doc """
  Parses a hex string, but returns `:error` instead
  of raising if hex is invalid.

  ## Examples

    iex> ABI.Hex.decode_hex("0xaabb")
    {:ok, <<170, 187>>}

    iex> ABI.Hex.decode_hex("aabb")
    {:ok, <<170, 187>>}

    iex> ABI.Hex.decode_hex("0xgggg")
    :invalid_hex
  """
  @spec decode_hex(String.t()) :: {:ok, t()} | :error
  def decode_hex(b), do: decode_hex_(b)

  @doc """
  Alias for `decode_hex`.

  ## Examples

    iex> ABI.Hex.from_hex("0xaabb")
    {:ok, <<0xaa, 0xbb>>}
  """
  @spec from_hex(t()) :: String.t()
  def from_hex(b), do: decode_hex(b)

  @doc """
  Alias for `decode_hex!`.

  ## Examples

    iex> ABI.Hex.from_hex!("0xaabb")
    <<0xaa, 0xbb>>
  """
  @spec from_hex!(t()) :: String.t()
  def from_hex!(b), do: decode_hex!(b)

  @doc """
  Parses a hex string and raises if invalid.

  ## Examples

    iex> ABI.Hex.decode_hex!("aabb")
    <<170, 187>>

    iex> ABI.Hex.decode_hex!("0xggaabb")
    ** (ABI.Hex.HexError) invalid hex: "0xggaabb"
  """
  @spec decode_hex!(String.t()) :: t()
  def decode_hex!(b) do
    case decode_hex_(b) do
      {:ok, hex} ->
        hex

      _ ->
        raise HexError, "invalid hex: \"#{b}\""
    end
  end

  @doc """
  Parses an Ethereum 20-bytes hex string.

  Identical to `decode_hex!/1` except fails if
  string is not exactly 20-bytes.

  ## Examples

    iex> ABI.Hex.decode_address!("0x0000000000000000000000000000000000000001")
    <<1::160>>

    iex> ABI.Hex.decode_address!("0xaabb")
    ** (ABI.Hex.HexError) invalid hex address: "0xaabb"
  """
  @spec decode_address!(String.t()) :: t() | no_return()
  def decode_address!(hex) do
    decode_sized!(hex, 20, "invalid hex address")
  end

  @doc """
  Parses an Ethereum 32-bytes hex string.

  Identical to `decode_hex!/1` except fails if
  string is not exactly 32-bytes.

  ## Examples

    iex> ABI.Hex.decode_word!("0x0000000000000000000000000000000000000000000000000000000000000001")
    <<1::256>>

    iex> ABI.Hex.decode_word!("0xaabb")
    ** (ABI.Hex.HexError) invalid hex word: "0xaabb"
  """
  @spec decode_word!(String.t()) :: t() | no_return()
  def decode_word!(hex) do
    decode_sized!(hex, 32, "invalid hex word")
  end

  @doc """
  Parses an Ethereum x-bytes hex string.

  Identical to `decode_hex!/1` except fails if
  string is not exactly x-bytes.

  ## Examples

    iex> ABI.Hex.decode_sized!("0x001122", 3)
    <<0x00, 0x11, 0x22>>

    iex> ABI.Hex.decode_sized!("0xaabb", 3)
    ** (ABI.Hex.HexError) invalid 3-byte sized hex: "0xaabb"
  """
  @spec decode_sized!(String.t(), integer(), String.t() | nil) :: t() | no_return()
  def decode_sized!(hex, sz, msg \\ nil) do
    res = decode_hex!(hex)

    if byte_size(res) == sz do
      res
    else
      raise HexError,
            (case msg do
               nil ->
                 "invalid #{sz}-byte sized hex: \"#{hex}\""

               _ ->
                 "#{msg}: \"#{hex}\""
             end)
    end
  end

  @doc """
  Parses hex is value is not nil, otherwise returns `nil`.

  ## Examples

    iex> ABI.Hex.decode_maybe_hex!("0xaabb")
    <<170, 187>>

    iex> ABI.Hex.decode_maybe_hex!(nil)
    nil
  """
  @spec decode_maybe_hex!(String.t() | nil) :: t() | nil
  def decode_maybe_hex!(h) when is_nil(h), do: nil
  def decode_maybe_hex!(h) when is_binary(h), do: decode_hex!(h)

  @doc """
  Parses hex value as a big-endian integer. Raises if invalid.

  ## Examples

    iex> ABI.Hex.decode_hex_number!("0xaabb")
    0xaabb

    iex> ABI.Hex.decode_hex_number!("0xgggg")
    ** (ABI.Hex.HexError) invalid hex number: "0xgggg"
  """
  @spec decode_hex_number!(String.t()) :: integer() | no_return()
  def decode_hex_number!(b) do
    case decode_hex_number(b) do
      {:ok, x} ->
        x

      :invalid_hex ->
        raise HexError, "invalid hex number: \"#{b}\""
    end
  end

  @doc """
  Parses hex value as a big-endian integer.

  ## Examples

    iex> ABI.Hex.decode_hex_number("0xaabb")
    {:ok, 0xaabb}

    iex> ABI.Hex.decode_hex_number("0xgggg")
    :invalid_hex
  """
  @spec decode_hex_number(String.t()) :: {:ok, integer()} | :error
  def decode_hex_number(b) do
    with {:ok, x} <- decode_hex(b), do: {:ok, :binary.decode_unsigned(x)}
  end

  @doc """
  Encodes a given value as a lowercase hex string, starting with `0x`.

  ## Examples

    iex> ABI.Hex.encode_hex(<<0xaa, 0xbb>>)
    "0xaabb"
  """
  @spec encode_hex(t()) :: String.t()
  def encode_hex(b) when is_binary(b), do: "0x" <> Base.encode16(b, case: :lower)

  @doc """
  Alias for `encode_hex`.

  ## Examples

    iex> ABI.Hex.to_hex(<<0xaa, 0xbb>>)
    "0xaabb"
  """
  @spec to_hex(t()) :: String.t()
  def to_hex(b), do: encode_hex(b)

  @doc ~S"""
  Encodes hex, in CAPITALS.

  ## Examples

    iex> ABI.Hex.encode_big_hex(<<0xcc, 0xdd>>)
    "0xCCDD"
  """
  @spec encode_big_hex(binary()) :: String.t()
  def encode_big_hex(hex) when is_binary(hex), do: "0x" <> Base.encode16(hex)

  @doc ~S"""
  Encodes hex, striping any leading zeros.

  ## Examples

    iex> ABI.Hex.encode_short_hex(<<0xc>>)
    "0xC"

    iex> ABI.Hex.encode_short_hex(12)
    "0xC"

    iex> ABI.Hex.encode_short_hex(<<0x0>>)
    "0x0"
  """
  @spec encode_short_hex(binary() | integer()) :: String.t()
  def encode_short_hex(hex) when is_binary(hex) do
    enc = Base.encode16(hex)

    "0x" <>
      case String.replace_leading(enc, "0", "") do
        "" ->
          "0"

        els ->
          els
      end
  end

  def encode_short_hex(v) when is_integer(v), do: encode_short_hex(:binary.encode_unsigned(v))

  @doc """
  If input is a tuple `{:ok, x}` then returns a tuple `{:ok, hex}`
  where `hex = encode(x)`. Otherwise, returns its input unchanged.

  ## Examples

    iex> ABI.Hex.encode_hex_result({:ok, <<0xaa, 0xbb>>})
    {:ok, "0xaabb"}

    iex> ABI.Hex.encode_hex_result({:error, 55})
    {:error, 55}
  """
  @spec encode_hex_result({:ok, t()} | term()) :: {:ok, String.t()} | term()
  def encode_hex_result({:ok, b}) when is_binary(b), do: {:ok, encode_hex(b)}
  def encode_hex_result(els), do: els

  @doc """
  If input is non-`nil`, returns input encoded as a hex string. Otherwise,
  returns `nil`.

  ## Examples

    iex> ABI.Hex.maybe_encode_hex(<<0xaa, 0xbb>>)
    "0xaabb"

    iex> ABI.Hex.maybe_encode_hex(nil)
    nil
  """
  @spec maybe_encode_hex(t() | nil) :: String.t() | nil
  def maybe_encode_hex(b) when is_nil(b), do: nil
  def maybe_encode_hex(b) when is_binary(b), do: encode_hex(b)

  # Core function to decode hex
  @spec decode_hex_(String.t()) :: {:ok, t()} | :error
  defp decode_hex_("0x" <> b) when is_binary(b), do: decode_hex_(b)

  defp decode_hex_(b) when is_binary(b) do
    hex_padded =
      if rem(byte_size(b), 2) == 1 do
        "0" <> b
      else
        b
      end

    case Base.decode16(hex_padded, case: :mixed) do
      res = {:ok, _} ->
        res

      :error ->
        :invalid_hex
    end
  end

  @doc false
  def deep_encode_binaries(x) when is_binary(x), do: to_hex(x)
  def deep_encode_binaries(l) when is_list(l), do: Enum.map(l, &deep_encode_binaries/1)

  def deep_encode_binaries(t) when is_tuple(t),
    do: List.to_tuple(Enum.map(Tuple.to_list(t), &deep_encode_binaries/1))

  def deep_encode_binaries(els), do: els
end
