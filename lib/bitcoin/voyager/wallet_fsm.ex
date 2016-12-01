defmodule Bitcoin.Voyager.WalletFSM do
  alias __MODULE__, as: State
  alias Libbitcoin.Client
  alias Bitcoin.Voyager.Util
  alias Bitcoin.Voyager.Handlers.Blockchain
  alias Bitcoin.Voyager.Cache

  defstruct [addresses: HashSet.new, parent: nil, page: 0, per_page: 10,
             ref: nil, height: -1, txrefs: [], wallet: nil, transactions: %{}]

  @empty_wallet  %{balance: 0, transactions: [], unspent: [], height: 0}
  @unspent_hash Base.decode16!("0000000000000000000000000000000000000000000000000000000000000000")

  def client do
    :pg2.get_closest_pid(Bitcoin.Voyager.Client)
  end

  def start_link(addresses, page \\ 0, per_page \\ 20, parent \\ self) do
    :gen_fsm.start_link __MODULE__, [addresses, page, per_page, parent], []
  end

  def init([addresses, page, per_page, parent]) when is_binary(page) do
    {page, ""} = Integer.parse(page)
    init([addresses, page, per_page, parent])
  end
  def init([addresses, page, per_page, parent]) when is_binary(per_page) do
    {per_page, ""} = Integer.parse(per_page)
    init([addresses, page, per_page, parent])
  end
  def init([addresses, page, per_page, parent]) do
    addresses_set = Enum.reduce addresses, HashSet.new, &HashSet.put(&2, &1)
    state = %State{addresses: addresses_set, parent: parent, page: page, per_page: per_page}
    {:ok, state} = fetch_last_height(state)
    {:ok, :height, state}
  end

  def handle_info({:libbitcoin_client_error, command, _ref, error}, :height, state) do
    send state.parent, {:error, {command, error}}
    {:stop, {:error, error}, state}
  end
  def handle_info({:libbitcoin_client, "blockchain.fetch_last_height", _ref, height}, :height, state) do
    {:ok, state} = fetch_histories(state)
    {:next_state, :history, %State{state | height: height}}
  end
  def handle_info({:libbitcoin_client, "address.fetch_history", ref, history}, :history, %State{ref: refs, height: height} = state) do
    refs = Map.delete(refs, ref)
    {:ok, state} = map_wallet(history, %State{state | ref: refs})
    if Map.size(refs) == 0 do
      wallet = reduce_wallet(state.txrefs)
      wallet = %{wallet | height: height}
      if length(wallet[:transactions]) > 0 do
        {:ok, state} = fetch_transactions(%State{state | wallet: wallet})
        {:next_state, :transactions, state}
        else
          send state.parent, {:wallet, wallet}
          {:stop, :normal, state}
        end
    else
      {:next_state, :history, state}
    end
  end
  def handle_info({:libbitcoin_client, cmd, ref, raw_transaction}, :transactions, %State{ref: refs, transactions: transactions} = state)
    when cmd in ["transaction_pool.fetch_transaction", "blockchain.fetch_transaction"] do
    hash = Map.get(refs, ref)
    refs = Map.delete(refs, ref)
    state = fetched_transaction(hash, raw_transaction, %State{state | ref: refs})
    if Map.size(refs) == 0 do
      {:ok, state} = send_wallet(state)
      {:stop, :normal, state}
    else
      {:next_state, :transactions, state, 5000}
    end
  end
  def handle_info({:libbitcoin_client_error, _cmd, ref, :timeout}, :transactions, %State{ref: refs} = state) do
    hash = Map.get(refs, ref)
    refs = Map.delete(refs, ref)
    refs = fetch_transaction(%{hash: hash, height: 0}, refs)
    :timer.send_after(5000, :give_up)
    {:next_state, :transactions, %State{state | ref: refs}}
  end
  def handle_info({:libbitcoin_client_error, _cmd, ref, :not_found}, :transactions, %State{ref: refs} = state) do
    hash = Map.get(refs, ref)
    refs = Map.delete(refs, ref)
    state = %State{state | ref: refs}
    if Map.size(refs) == 0 do
      {:ok, state} = send_wallet(state)
      {:stop, :normal, state}
    else
      {:next_state, :transactions, state}
    end
  end
  def handle_info(:give_up, :transactions, state) do
    send state.parent, {:wallet, state.wallet}
    {:stop, :gave_up, state}
  end

  def terminate(_, _, _state) do
    :ok
  end

  def fetch_last_height(state) do
    {:ok, ref} = Client.last_height(client)
    {:ok, %State{state | ref: Map.put(%{}, ref, nil)}}
  end

  def fetch_histories(%State{addresses: addresses} = state) do
    refs = Enum.reduce addresses, %{}, fn(address, acc) ->
      {:ok, ref} = Client.address_history(client, address, 0)
      Map.put(acc, ref, address)
    end
    {:ok, %State{state | ref: refs}}
  end

  def fetch_transactions(%State{wallet: %{transactions: txs, unspent: unspent} = wallet, page: page, per_page: per_page} = state) do
    start_index = page * per_page
    transactions = Enum.slice(txs, start_index, start_index + per_page) ++ unspent
    transactions = Enum.uniq_by(transactions, fn(%{hash: hash}) -> hash end)
    state = Enum.reduce transactions, state, &fetch_cached_transaction(&1, &2)
    refs = Enum.reduce transactions, %{}, &fetch_transaction(&1, &2)
    {:ok, %State{state | ref: refs, wallet: %{wallet | transactions: transactions}}}
  end

  def fetch_cached_transaction(%{hash: hash, height: height}, state) do
    case Cache.get(Blockchain.TransactionHandler, %{cache_height: height}, [hash]) do
      {:ok, raw_transaction} ->
        fetched_transaction(hash, raw_transaction, state)
      :not_found ->
        state
    end
  end
  def fetch_transaction(%{hash: hash, height: 0}, acc) do
    {:ok, ref} = Client.pool_transaction(client, hash)
    Map.put(acc, ref, hash)
  end
  def fetch_transaction(%{hash: hash, height: height}, acc) do
    {:ok, ref} = Client.blockchain_transaction(client, hash)
    Map.put(acc, ref, hash)
  end

  def fetched_transaction(hash, raw_transaction, state) do
    transaction = :libbitcoin.tx_decode(raw_transaction) |> Map.delete(:value)
    transactions = Map.put(state.transactions, hash, transaction)
    %State{state | transactions: transactions}
  end

  def map_wallet(history, %State{txrefs: txrefs} = state) do
    {:ok, %State{state | txrefs: txrefs ++ history}}
  end

  def merge_txrefs(txrefs), do: merge_txrefs(txrefs, [])
  def merge_txrefs([], transactions), do: transactions
  def merge_txrefs([%{hash: hash} = txref|txrefs], [%{hash: hash} = transaction|acc]) do
    transaction = %{transaction | value: transaction.value + txref_value(txref.type, txref.value)}
    merge_txrefs(txrefs, [transaction|acc])
  end
  def merge_txrefs([%{hash: _hash} = txref|txrefs], acc) do
    transaction = %{
      hash: txref.hash, height: txref.height, type: txref.type,
      value: txref_value(txref.type, txref.value)}
    merge_txrefs(txrefs, [transaction|acc])
  end

  def filter_unconfirmed(txrefs), do: filter_unconfirmed(txrefs, [])
  def filter_unconfirmed([%{height: 0} = txref|txrefs], acc) do
    filter_unconfirmed(txrefs, acc ++ [txref])
  end
  def filter_unconfirmed(txrefs, acc) do
    txrefs ++ acc
  end

  def txref_value(:output, value), do: value
  def txref_value(:spend, value), do: -value

  def send_wallet(state) do
    {:ok, state} = reduce_transactions(state)
    {:ok, state} = reduce_unspent(state)
    send state.parent, {:wallet, state.wallet}
    {:ok, state}
  end

  def reduce_wallet(txrefs) do
    wallet = Enum.reduce txrefs, @empty_wallet, fn
      (%{spend_hash: @unspent_hash, value: value} = row,
       %{balance: balance, transactions: transactions, unspent: unspent} = acc) ->
        %{acc | balance: balance + value,
                transactions: [format_output(row)|transactions],
                unspent: [format_unspent(row)|unspent]}
      (row, %{transactions: transactions} = acc) ->
        %{acc | transactions: [format_output(row),format_spend(row)|transactions]}
    end
    %{wallet | transactions: format_transactions(wallet[:transactions])}
  end

  def reduce_transactions(%State{addresses: addresses, wallet: wallet, transactions: transactions} = state) do
    transactions = wallet
      |> Map.get(:transactions)
      |> Enum.map(&reduce_transaction(addresses, transactions, &1))

    {:ok, %State{state | wallet: %{wallet | transactions: transactions}}}
  end

  def reduce_transaction(addresses, transactions, %{hash: hash, type: type} = row) do
    case Map.get(transactions, hash) do
      %{inputs: inputs, outputs: outputs} = transaction ->
        row = Map.delete(row, :hash)
        address_targets = if type == :spend, do: outputs, else: inputs
        addrs = (for %{address: address} <- address_targets, do: address)
          |> Enum.filter(fn(addr) -> !Set.member?(addresses, addr) end)
        row
          |> Map.merge(%{addresses: addrs})
          |> Map.merge(transaction)
      nil ->
        row
          |> Map.put(:hash, Base.encode16(hash, case: :lower))
    end
  end
  def reduce_transaction(addresses, transactions, row) do
    row
  end

  def reduce_unspent(%State{addresses: addresses, wallet: wallet, transactions: transactions} = state) do
    unspent = wallet |> Map.get(:unspent) |> Enum.map(fn(%{hash: hash, index: index} = row) ->
      case Map.get(transactions, hash) do
        %{outputs: outputs} = transaction ->
          output = Enum.at(outputs, index)
            |> Map.put(:index, index)
            |> Map.put(:checksum, checksum(hash, index))
          out = transaction
            |> Map.delete(:inputs)
            |> Map.delete(:outputs)
            |> Map.merge(output)
        nil ->
          row
            |> Map.put(:hash, Base.encode16(hash, case: :lower))
            |> Map.put(:checksum, checksum(hash, index))
      end
    end)

    {:ok, %State{state | wallet:  %{wallet | unspent: unspent}}}
  end

  def sort_txrefs(txrefs) do
    Enum.sort txrefs, fn(a, b) ->
      if a.height != b.height do
        a.height > b.height
      else
        if a.hash != b.hash do
          a.hash < b.hash
        else
          a.index < b.index
        end
      end
    end
  end

  def format_transactions(txrefs) do
    txrefs
      |> sort_txrefs
      |> merge_txrefs
      |> filter_unconfirmed
      |> Enum.reverse
  end

  def format_unspent(row) do
    %{hash: row.output_hash,
      index: row.output_index,
      height: row.output_height,
      value: row.value,
      type: :unspent}
  end

  def format_output(row) do
    %{hash: row.output_hash,
      index: row.output_index,
      height: row.output_height,
      value: row.value,
      type: :output}
  end

  def format_spend(row) do
    %{hash: row.spend_hash,
      index: row.spend_index,
      height: row.spend_height,
      value: row.value,
      type: :spend}
  end

  def to_hex(hash) do
    Base.encode16(hash, case: :lower)
  end

  def from_hex(hash) do
    Base.decode16(hash, case: :lower)
  end

  def checksum(hash, index) do
    Libbitcoin.Client.spend_checksum(hash, index)
      |> Integer.to_string(16)
      |> String.downcase
  end

end

