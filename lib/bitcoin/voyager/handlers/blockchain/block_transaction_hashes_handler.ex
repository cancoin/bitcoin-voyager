defmodule Bitcoin.Voyager.Handlers.Blockchain.BlockTransactionHashesHandler do
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

  def command, do: :block_transaction_hashes

  def transform_args(%{hash: hash}) do
    case Util.decode_hex(hash) do
      {:ok, hash} ->
        {:ok, hash}
      _ ->
        {:error, :invalid_hash}
    end
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(transactions) do
    {:ok, transactions} = Util.encode_hex(transactions)
    {:ok, %{transactions: transactions}}
  end

  def cache_name, do: :block_transaction_hashes

  def cache_ttl, do: 0

  def cache_key([hash]) do
    hash
  end

  def cache_serialize(hashes) do
    :binary.list_to_bin(hashes)
  end

  def cache_deserialize(hashes) do
    cache_deserialize(hashes, [])
  end

  defp cache_deserialize(<<>>, acc) do
    Enum.reverse(acc)
  end

  defp cache_deserialize(<<hash :: binary-size(32), tail :: binary>>, acc) do
    cache_deserialize(tail, [hash|acc])
  end

end
