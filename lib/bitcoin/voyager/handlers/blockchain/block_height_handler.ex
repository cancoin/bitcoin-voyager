defmodule Bitcoin.Voyager.Handlers.Blockchain.BlockHeightHandler do
  @moduledoc """
  Get last height from server
  """

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

end
