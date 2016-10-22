defmodule Bitcoin.Voyager.Handlers.TransactionPool.TransactionHandler do
  alias Bitcoin.Voyager.Handlers.Blockchain.TransactionHandler
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

  def command, do: fn(client, hash, _height, owner) ->
    Libbitcoin.Client.pool_transaction(client, hash, owner)
  end

  defdelegate transform_args(parmas), to: TransactionHandler
  defdelegate transform_reply(reply), to: TransactionHandler
  defdelegate cache_name, to: TransactionHandler
  defdelegate cache_ttl, to: TransactionHandler
  defdelegate cache_key(params), to: TransactionHandler
  defdelegate cache_serialize(value), to: TransactionHandler
  defdelegate cache_deserialize(value), to: TransactionHandler

end
