defmodule Bitcoin.Voyager.Subscriber do
  alias Libbitcoin.Client.Sub, as: Subscriber
  import Logger
  use GenServer

  defmodule State do
    defstruct type: nil, uri: nil, client: nil
  end
  def start_link(type, uri) when type in [:heartbeat, :transaction, :block] do
    GenServer.start_link(__MODULE__, [type, uri], [name: :"subscriber.#{type}"])
  end

  def init([type, nil]) do
    Logger.info("disabling #{type} subscriptions due to missing configuration")
    {:ok, %State{type: type, uri: nil, client: nil}}
  end
  def init([type, uri]) do
    {:ok, client} = Subscriber.start_link(type, uri)
    :ok = Subscriber.controlling_process(client)
    {:ok, %State{type: type, uri: uri, client: client}}
  end

  def handle_info({:libbitcoin_client, type, payload}, %State{type: type, client: client} = state) do
    :ok = Subscriber.ack_message(client)
    :ok = broadcast_payload(type, payload)
    {:noreply, state}
  end

  def broadcast_payload(:transaction = type, payload) when is_binary(payload) do
    broadcast_payload(type, :libbitcoin.tx_decode(payload))
  end
  def broadcast_payload(type, payload) do
    :gproc.send({:p, :l, "subscribe.#{type}"}, {"subscribe.#{type}", payload})
    :ok
  end
end
