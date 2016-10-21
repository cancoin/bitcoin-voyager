defmodule Bitcoin.Voyager.Handlers.Blockchain.TransactionIndexHandler do
  alias Bitcoin.Voyager.Util
  use Bitcoin.Voyager.Handler

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

  def cache_name, do: :transaction_index

  def cache_ttl, do: 0

  def cache_key([hash]) do
    hash
  end

  def cache_serialize({height, index}) do
    <<height :: unsigned-integer-size(64), index :: unsigned-integer-size(64)>>
  end

  def cache_deserialize(<<height :: unsigned-integer-size(64), index :: unsigned-integer-size(64)>>) do
    {height, index}
  end



end

