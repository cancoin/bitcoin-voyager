defmodule Bitcoin.Voyager.Cache do

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
    caches = :application.get_env(:bitcoin_voyager, :caches, @caches)
    Enum.each caches, fn({name, size}) ->
      {:ok, _} = :cherly_sup.start_child(name, size)
    end
    :ok
  end

  def get(module, params \\ %{}) do
    case module.cache_name do
      nil -> :not_found
      name ->
        key = module.cache_key(params)
        :cherly_server.get(name, key) |> deserialize(module)
    end
  end

  def put(module, params, value) do
    case module.cache_name do
      nil -> :ok
      name ->
        :cherly_server.put(name,
          module.cache_key(params),
          module.cache_serialize(value),
          module.cache_ttl)
    end
  end

  defp deserialize(:not_found, _module), do: :not_found
  defp deserialize({:ok, reply}, module) do
    module.cache_deserialize(reply) |> module.transform_reply
  end

end
