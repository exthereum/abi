defmodule ABI.Math do
  @moduledoc """
  Helper functions for ABI's math functions.
  """

  @doc """
  Simple function to compute modulo function to work on integers of any sign.

  ## Examples

      iex> ABI.Math.mod(5, 2)
      1

      iex> ABI.Math.mod(-5, 1337)
      1332

      iex> ABI.Math.mod(1337 + 5, 1337)
      5

      iex> ABI.Math.mod(0, 1337)
      0
  """
  def mod(x, n) when x > 0, do: rem(x, n)
  def mod(x, n) when x < 0, do: rem(n + x, n)
  def mod(0, _n), do: 0

  @doc """
  Returns the keccak sha256 of a given input.

  ## Examples

      iex> ABI.Math.kec("hello world")
      <<71, 23, 50, 133, 168, 215, 52, 30, 94, 151, 47, 198, 119, 40, 99,
        132, 248, 2, 248, 239, 66, 165, 236, 95, 3, 187, 250, 37, 76, 176,
        31, 173>>

      iex> ABI.Math.kec("hello world", :ex_keccak)
      <<71, 23, 50, 133, 168, 215, 52, 30, 94, 151, 47, 198, 119, 40, 99,
        132, 248, 2, 248, 239, 66, 165, 236, 95, 3, 187, 250, 37, 76, 176,
        31, 173>>

      iex> ABI.Math.kec(<<0x01, 0x02, 0x03>>)
      <<241, 136, 94, 218, 84, 183, 160, 83, 49, 140, 212, 30, 32, 147, 34,
        13, 171, 21, 214, 83, 129, 177, 21, 122, 54, 51, 168, 59, 253, 92,
        146, 57>>
  """
  @spec kec(binary()) :: binary()
  def kec(data, provider_name \\ Application.get_env(:abi, :keccak, :ex_sha3)) do
    keccak_hash!(data, provider_name)
  end

  defp keccak_hash!(data, :ex_sha3), do: ExSha3.keccak_256(data)

  defp keccak_hash!(data, :ex_keccak) do
    data
    |> ExKeccak.hash_256()
    |> case do
      {:ok, hash} -> hash
      {:error, error} -> raise error
    end
  end
end
