defmodule Bitcoin.Voyager.Subscriber do
  alias Libbitcoin.Client.Sub, as: Subscriber
  alias Bitcoin.Voyager.Util
  alias Bitcoin.Voyager.Handlers.Blockchain
  alias Bitcoin.Voyager.Cache
  import Logger
  use GenServer

  defmodule State do
    defstruct type: nil, uri: nil, client: nil
  end
  def start_link(type, uri) when type in [:heartbeat, :transaction, :block] do
    GenServer.start_link(__MODULE__, [type, uri], [name: :"subscriber.#{type}"])
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
    case :libbitcoin.tx_decode(payload) do
      %{hash: hash} = transaction ->
        hash = Base.decode16!(hash, case: :lower)
        :ok = Cache.put(Blockchain.TransactionHandler, [hash], payload, %{cache_height: 0})
        broadcast_payload(type, transaction)
      _ ->
        :ok
    end
  end
  def broadcast_payload(:block = type, {height, raw_header, hashes} = payload) when is_binary(raw_header) do
    case :libbitcoin.header_decode(raw_header) do
      %{hash: hash} = header ->
        hash = Base.decode16!(hash, case: :lower)
        :ok = Cache.set_chain_state(cache_height: height)
        :ok = Cache.put(Blockchain.BlockHeightHandler,[hash], height, %{cache_height: height})
        :ok = Cache.put(Blockchain.BlockHeaderHandler, [height], raw_header, %{cache_height: height})
        broadcast_payload(type, {height, header, hashes})
      _ ->
        :ok
    end
  end
  def broadcast_payload(type, payload) do
    :gproc.send({:p, :l, "subscribe.#{type}"}, {"subscribe.#{type}", payload})
    :ok
  end
end
