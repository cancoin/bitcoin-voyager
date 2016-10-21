defmodule Bitcoin.Voyager.Handlers.Blockchain.LastHeightHandler do
  use Bitcoin.Voyager.Handler

  def command, do: :last_height

  def transform_args(_params) do
    {:ok, []}
  end

  def transform_reply(reply) do
    {:ok, %{height: reply}}
  end

  def cache_key([]) do
    "latest"
  end

  def cache_ttl, do: 10

  def cache_name, do: :height

  def cache_deserialize(value) do
    :binary.decode_unsigned(value)
  end
end
