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
    :ets.new(@chain_state_table, [:named_table, :public, read_concurrency: true])
    caches = :application.get_env(:bitcoin_voyager, :caches, @caches)
    Enum.each caches, fn({name, size}) ->
      {:ok, _} = :cherly_sup.start_child(name, size)
    end
    :ok
  end

  def set_chain_state(state) do
    Enum.each state, fn({key, value}) ->
      :ets.insert(@chain_state_table, {key, value})
    end
    :ok
  end

  def get_chain_state(key) do
    case :ets.lookup(@chain_state_table, key) do
      [] -> nil
      state -> state[key]
    end
  end

  def get(module), do: get(module, %{}, [])

  def get(module, %{cache_height: cache_height} = params, transformed_params) when is_integer(cache_height) do
    case module.cache_name do
      nil -> :not_found
      name ->
        key = module.cache_key(transformed_params)
        :cherly_server.get(name, key) |> deserialize(module, params)
    end
  end
  def get(module, %{cache_height: cache_height} = params, transformed_params) when is_binary(cache_height) do
    get(module, Map.put(params, :cache_height, String.to_integer(cache_height)), transformed_params)
  end
  def get(module, [], transformed_params) do
    get(module, %{}, transformed_params)
  end
  def get(module, params, transformed_params) do
    get(module, Map.put(params, :cache_height, 0), transformed_params)
  end

  def put(module, params, value) do
    cache_height = get_chain_state(:height)
    put(module, params, value, %{cache_height: cache_height})
  end

  def put(module, params, value, %{cache_height: nil}) do
    put(module, params, value, %{cache_height: 0})
  end
  def put(module, params, value, %{cache_height: cache_height}) do
    case module.cache_name do
      nil -> :ok
      name ->
        serialized = module.cache_serialize(value)
        :cherly_server.put(name,
          module.cache_key(params),
          << cache_height :: unsigned-integer-size(32), serialized :: binary>>,
          module.cache_ttl)
    end
  end

  defp deserialize(:not_found, _module, _params) do
    :not_found
  end
  defp deserialize({:ok, <<cached_height :: unsigned-integer-size(32), _cache_reply :: binary>>}, module, %{cache_height: cache_height}) 
    when cached_height < cache_height, do: :not_found
  defp deserialize({:ok, <<_height :: unsigned-integer-size(32), cache_reply :: binary>>}, module, params) do
    case module.cache_deserialize(cache_reply) do
      :not_found -> :not_found
      value -> module.transform_reply(value)
    end
  end

end
