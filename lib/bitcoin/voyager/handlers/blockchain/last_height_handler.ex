defmodule Bitcoin.Voyager.Handlers.Blockchain.LastHeightHandler do

  @moduledoc """
  """

  def command, do: :last_height

  def transform_args(_params) do
    {:ok, []}
  end

  def transform_reply(reply) do
    {:ok, %{height: reply}}
  end

end
