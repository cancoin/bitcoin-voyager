defmodule Bitcoin.Voyager.AddressSubscriber do
  alias Libbitcoin.Client.Sub, as: Subscriber
  import Logger
  use GenServer

  defmodule State do
    defstruct []
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: :"subscriber.address"])
  end

  def init(_) do
    true = :gproc.reg({:p, :l, "subscribe.transaction"}, self)
    {:ok, %State{}}
  end

  def handle_info({"subscribe.transaction", %{inputs: inputs, outputs: outputs} = transaction}, state) do
    addresses = extract_addresses(transaction)
    :ok = broadcast_transaction(addresses, transaction)
    {:noreply, state}
  end

  def broadcast_transaction(addresses, transaction) do
    for address <- addresses do
      :gproc.send({:p, :l, "subscribe.address.#{address}"}, {"subscribe.address", address, transaction})
    end
    :ok
  end

  def extract_addresses(%{inputs: inputs, outputs: outputs}) do
    Enum.map(inputs ++ outputs, &extract_address(&1))
      |> Enum.reject(&(&1 == nil))
  end

  def extract_address(%{address: address}), do: address
  def extract_address(_), do: nil
end
