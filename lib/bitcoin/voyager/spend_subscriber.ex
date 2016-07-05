defmodule Bitcoin.Voyager.SpendSubscriber do
  alias Libbitcoin.Client.Sub, as: Subscriber
  import Logger
  use GenServer

  defmodule State do
    defstruct []
  end

  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: :"subscriber.spend"])
  end

  def init(_) do
    true = :gproc.reg({:p, :l, "subscribe.transaction"}, self)
    {:ok, %State{}}
  end

  def handle_info({"subscribe.transaction", %{inputs: inputs} = transaction}, state) do
    checksums = extract_input_checksums(transaction)
    :ok = broadcast_checksums(checksums, transaction)
    {:noreply, state}
  end

  def broadcast_checksums(checksums, %{hash: hash}) do
    for checksum <- checksums do
      :gproc.send({:p, :l, "subscribe.spend.#{checksum}"}, {"subscribe.spend", checksum, hash})
    end
    :ok
  end

  def extract_input_checksums(%{inputs: inputs}) do
    Enum.map(inputs, &checksum(&1))
      |> Enum.reject(&(&1 == nil))
  end

  def checksum(%{previous_output: %{hash: hash, index: index}}) do
    Base.decode16!(hash, case: :lower)
      |> Libbitcoin.Client.spend_checksum(index)
      |> Integer.to_string(16)
      |> String.downcase
  end
  def checksum(_), do: nil

end

