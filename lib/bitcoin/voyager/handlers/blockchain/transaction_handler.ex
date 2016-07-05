defmodule Bitcoin.Voyager.Handlers.Blockchain.TransactionHandler do
  alias Bitcoin.Voyager.Util

  @moduledoc """
  """

  def command, do: :blockchain_transaction

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
