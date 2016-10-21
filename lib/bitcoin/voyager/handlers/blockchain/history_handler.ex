defmodule Bitcoin.Voyager.Handlers.Blockchain.HistoryHandler do
  alias Bitcoin.Voyager.Handlers.Address
  use Bitcoin.Voyager.Handler

  def command, do: :blockchain_history

  defdelegate transform_args(args), to: Address.HistoryHandler

  defdelegate transform_reply(reply), to: Address.History2Handler

  def cache_key([address, count]) do
    "#{address}#{:binary.encode_unsigned(count)}"
  end

  def cache_ttl, do: 10

  def cache_name, do: :history2
end
