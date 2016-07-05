defmodule Bitcoin.Voyager.Supervisor do
  use Supervisor

  alias Bitcoin.Voyager

  @doc false
  def start_link(config) do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [config])
  end

  @doc """
  Subscribe to libbitcoin server event notifications
  """
  def init([config]) do
    children = [
      supervisor(Voyager.ClientSupervisor, [config], restart: :permanent),
      supervisor(Voyager.Subscriber.Supervisor, [config], restart: :permanent)
    ]
    supervise children, strategy: :one_for_one
  end
end
