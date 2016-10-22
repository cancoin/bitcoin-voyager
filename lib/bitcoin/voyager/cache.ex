defmodule Bitcoin.Voyager.Cache do

  @chain_state_table __MODULE__

  @caches [
    {:transaction, 100000},
    {:transaction_index, 100000},
    {:block_header,100000},
    {:block_height,100000},
    {:block_transaction_hashes, 100000},
    {:history, 100000},
    {:history2, 100000},
    {:spend, 100000},
    {:height, 100}
  ]

  def start_link do
    :ets.new(:chain_state_table, [:named_table, read_concurrency: true])
    caches = :application.get_env(:bitcoin_voyager, :caches, @caches)
    Enum.each caches, fn({name, size}) ->
      {:ok, _} = :cherly_sup.start_child(name, size)
    end
    :ok
  end

  def set_chain_state(state) do
    Enum.each state, fn({key, value}) ->
      :ets.insert(:chain_state_table, {key, value})
    end
    :ok
  end

  def get_chain_state(key) do
    case :ets.lookup(:chain_state_table, key) do
      [] -> nil
      state -> state[key]
    end
  end

  def get(module, params \\ %{}) do
    case module.cache_name do
      nil -> :not_found
      name ->
        key = module.cache_key(params)
        :cherly_server.get(name, key) |> deserialize(module, params)
    end
  end

  def put(module, params, value) do
    height = get_chain_state(:height)
    put(module, params, value, %{height: height})
  end

  def put(module, params, value, chain_state) do
    case module.cache_name do
      nil -> :ok
      name ->
        :cherly_server.put(name,
          module.cache_key(params),
          module.cache_serialize(value, chain_state),
          module.cache_ttl)
    end
  end

  defp deserialize(:not_found, _module, _params), do: :not_found
  defp deserialize({:ok, cache_reply}, module, params) do
    case module.cache_deserialize(cache_reply, params) do
      :not_found -> :not_found
      value -> module.transform_reply(value)
    end
  end

end
