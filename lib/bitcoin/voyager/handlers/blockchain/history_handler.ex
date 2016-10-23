defmodule Bitcoin.Voyager.Handlers.Blockchain.HistoryHandler do
  alias Bitcoin.Voyager.Handlers.Address.History2Handler
  use Bitcoin.Voyager.Handler

  def command, do: :blockchain_history
  def cache_name, do: :history2
  defdelegate transform_args(parmas), to: History2Handler
  defdelegate transform_reply(reply), to: History2Handler
  defdelegate cache_ttl, to: History2Handler
  defdelegate cache_key(params), to: History2Handler
  defdelegate cache_serialize(value), to: History2Handler
  defdelegate cache_deserialize(value), to: History2Handler

end
