defmodule Bitcoin.Voyager.Handlers.Blockchain.BlockHeightHandler do
  use Bitcoin.Voyager.Handler

  def command, do: :block_height

  def transform_args(%{hash: hash}) do
    case Base.decode16(hash, case: :lower) do
      {:ok, hash} ->
        {:ok, [hash]}
      :error ->
        {:error, :invalid}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(reply) do
    {:ok, %{height: reply}}
  end

  def cache_name, do: :block_height

  def cache_ttl, do: 10

  def cache_key([hash]) do
    hash
  end

  def cache_deserialize(value) do
    :binary.decode_unsigned(value)
  end
end
