defmodule Bitcoin.Voyager.Handlers.Blockchain.TransactionHandler do
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

  def command, do: fn(client, hash, _height, owner) ->
    Libbitcoin.Client.blockchain_transaction(client, hash, owner)
  end

  def transform_args(%{hash: hash, height: height} = params) when is_binary(height) do
    Map.put(params, :height, String.to_integer(height)) |> transform_args
  end
  def transform_args(%{hash: hash, height: height} = params) when is_integer(height) do
    case Util.decode_hex(hash) do
      {:ok, [hash]} -> {:ok, [hash, height]}
      error -> error
    end
  end
  def transform_args(%{hash: hash} = params) do
    Map.put(params, :height, 0) |> transform_args
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(reply) do
    tx = :libbitcoin.tx_decode(reply)
    {:ok, %{transaction: tx}}
  end

  def cache_name, do: :transaction

  def cache_ttl, do: 0

  def cache_key([hash]), do: hash
  def cache_key([hash, _height]), do: hash

  def cache_serialize(tx, %{height: height}) when is_integer(height) do
    <<height :: unsigned-integer-size(32), tx :: binary >>
  end
  def cache_serialize(tx, chain_state) do
    cache_serialize(tx, Map.put(chain_state, :height, 0))
  end

  def cache_deserialize(<<cached_height :: unsigned-integer-size(32), tx :: binary>>, [_hash, height])
    when height > cached_height do
    :not_found
  end
  def cache_deserialize(<<_height :: unsigned-integer-size(32), tx :: binary>>, _params) do
    tx
  end
end
