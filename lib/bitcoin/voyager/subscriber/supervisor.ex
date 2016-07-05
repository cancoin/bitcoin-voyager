defmodule Bitcoin.Voyager.Subscriber.Supervisor do
  use Supervisor

  @doc false
  def start_link(config) do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [config])
  end

  @doc """
  Subscribe to libbitcoin server event notifications
  """
  def init([config]) do
    children = [
      worker(Bitcoin.Voyager.Subscriber, [:heartbeat, config.heartbeat_uri], id: :heart_subscriber, restart: :permanent),
      worker(Bitcoin.Voyager.Subscriber, [:transaction, config.transaction_uri], id: :transaction_subscriber, restart: :permanent),
      worker(Bitcoin.Voyager.Subscriber, [:block, config.block_uri], id: :block_subscriber, restart: :permanent),
      worker(Bitcoin.Voyager.AddressSubscriber, [], id: :address_subscriber, restart: :permanent),
      worker(Bitcoin.Voyager.SpendSubscriber, [], id: :spend_subscriber, restart: :permanent)
    ]
    supervise children, strategy: :one_for_one
  end



end
