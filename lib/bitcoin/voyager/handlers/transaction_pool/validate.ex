defmodule Bitcoin.Voyager.Handlers.TransactionPool.ValidateHandler do
  alias Bitcoin.Voyager.Util

  def command, do: :validate

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

