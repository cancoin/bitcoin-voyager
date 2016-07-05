defmodule Bitcoin.Voyager.Handlers.Blockchain.HistoryHandler do
  alias Bitcoin.Voyager.Handlers.Address

  @moduledoc """
  Get last height from server
  """

  def command, do: :blockchain_history

  defdelegate transform_args(args), to: Address.HistoryHandler

  defdelegate transform_reply(reply), to: Address.History2Handler

end
