defmodule Bitcoin.Voyager.Handlers.Address.HistoryHandler do
  use Bitcoin.Voyager.Handler

  def command, do: :address_history
  #def command, do: "address.history"

  def transform_args(%{height: height} = args) when is_binary(height) do
    transform_args(%{args | height: String.to_integer(height)})
  end
  def transform_args(%{height: height, address: address}) when is_integer(height) do
    {:ok, [address, height]}
  end
  def transform_args(%{address: address} = r) do
    {:ok, [address, 0]}
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(reply) do
    {:ok, %{history: Enum.map(reply, &format_row(&1))}}
  end

  def format_row(%{output_hash: output_hash, spend_hash: spend_hash} = row) do
    %{row | output_hash: to_hex(output_hash), spend_hash: to_hex(spend_hash)}
  end

  def to_hex(hash) do
    Base.encode16(hash, case: :lower)
  end
  
  def cache_key([address, height]) do
    "#{address}#{:binary.encode_unsigned(height)}"
  end

  def cache_ttl, do: 10

  def cache_name, do: :history
end
