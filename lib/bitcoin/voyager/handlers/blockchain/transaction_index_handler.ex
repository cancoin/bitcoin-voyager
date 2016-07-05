defmodule Bitcoin.Voyager.Handlers.Blockchain.TransactionIndexHandler do
  alias Bitcoin.Voyager.Util

  @moduledoc """
  """

  def command, do: :transaction_index

  def transform_args(%{hash: hash}) do
    Util.decode_hex(hash)
  end
  def transform_args(_params) do
    {:error, :invalid}
  end


  def transform_reply({height, index}) do
    {:ok, %{height: height, index: index}}
  end

end

