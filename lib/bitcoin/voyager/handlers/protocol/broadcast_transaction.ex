defmodule Bitcoin.Voyager.Handlers.Protocol.BroadcastTransactionHandler do
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

  def command, do: :broadcast_transaction

  def transform_args(%{transaction: transaction}) do
    Util.decode_hex(transaction)
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(reply) do
    {:ok, %{status: reply}}
  end

end

