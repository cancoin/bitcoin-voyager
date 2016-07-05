defmodule Bitcoin.Voyager.Handlers.Blockchain.BlockTransactionHashesHandler do
  alias Bitcoin.Voyager.Util

  @moduledoc """
  """

  def command, do: :block_transaction_hashes

  def transform_args(%{hash: hash}) do
    case Util.decode_hex(hash) do
      {:ok, hash} ->
        {:ok, [hash]}
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

end
