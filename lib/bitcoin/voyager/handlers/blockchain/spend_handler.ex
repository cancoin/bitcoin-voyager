defmodule Bitcoin.Voyager.Handlers.Blockchain.SpendHandler do
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

  def command, do: :spend

  def transform_args(%{index: index} = args) when is_binary(index) do
    transform_args(%{args | index: String.to_integer(index)})
  end
  def transform_args(%{hash: hash, index: index}) do
    case Util.decode_hex(hash) do
      {nil} ->
        {:error, :invalid}
      {:ok, [hash]} ->
        {:ok, [hash, index]}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply({hash, index}) do
    {:ok, %{hash: Base.encode16(hash, case: :lower), index: index}}
  end
  def transform_reply(other) do
    {:ok, %{other: other}}
  end

  def cache_name, do: :spend

  def cache_ttl, do: 10

  def cache_key([hash, index]) do
    "#{hash}#{:binary.encode_unsigned(index)}"
  end

end

