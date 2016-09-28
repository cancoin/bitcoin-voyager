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
    Enum.each @caches, fn({name, size}) ->
      {:ok, _} = :cherly_sup.start_child(name, size)
    end

    :ok
  end
end
