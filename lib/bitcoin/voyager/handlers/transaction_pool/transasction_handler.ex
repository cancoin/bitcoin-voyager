defmodule Bitcoin.Voyager.Handlers.TransactionPool.TransactionHandler do
  alias Bitcoin.Voyager.Util

  def command, do: :pool_transaction

  def transform_args(%{hash: hash}) do
    Util.decode_hex(hash)
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(reply) do
    tx = :libbitcoin.tx_decode(reply)
    {:ok, %{transaction: tx}}
  end

end
