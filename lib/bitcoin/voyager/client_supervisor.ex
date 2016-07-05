defmodule Bitcoin.Voyager.ClientSupervisor do
  use Supervisor

  defmodule Client do
    @moduledoc false
    def start_link(uri) do
      case Libbitcoin.Client.start_link(uri) do
        {:ok, pid} ->
          :pg2.join(Bitcoin.Voyager.Client, pid)
          {:ok, pid}
        other ->
          other
      end
    end
  end

  def id(count), do: :"bitcoin_voyager_client_#{count}"

  @doc false
  def start_link(config) do
    :supervisor.start_link({:local, __MODULE__}, __MODULE__, [config])
  end

  def init([%{uri: uri, pool: pool} = config]) do
    size = Keyword.get(pool, :size, 1)

    children = Enum.map(0..size, fn(count) ->
      worker(Client, [uri], restart: :permanent, id: id(count))
    end)

    :ok = :pg2.create(Bitcoin.Voyager.Client)

    supervise children, [strategy: :one_for_one, max_restarts: 5, max_seconds: 60]
  end

end
