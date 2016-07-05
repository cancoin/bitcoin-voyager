defmodule Bitcoin.Voyager.WebSocketHandler do
  alias Bitcoin.Voyager.Util

  defmodule State do
    defstruct requests: %{}
  end

  def init(req, _opts) do
    {:cowboy_websocket, req, %State{}}
  end

  def websocket_handle({:text, info}, req, state) do
    case JSX.decode(info) do
      {:ok, payload} ->
        Util.atomify(payload) |> handle_command(req, state)
      {:error, _error} ->
        {:ok, req, state}
    end
  end

  def websocket_info({:libbitcoin_client, _command, ref, reply}, req, %State{requests: requests} = state) do
    {:ok, %{id: id, module: module}} = Map.fetch(requests, ref)
    requests = Map.delete(requests, ref)
    state = %State{state | requests: requests}
    case module.transform_reply(reply) do
      {:ok, reply} ->
        json = encode_reply(id, reply)
        {:reply, {:text, json}, req, state}
      {:error, reason} ->
        json = encode_error(id, reason)
        {:reply, {:text, json}, req, state}
    end
  end
  def websocket_info({:libbitcoin_client_error, _command, ref, error}, req, %State{requests: requests} = state) do
    {:ok, %{id: id}} = Map.fetch(requests, ref)
    requests = Map.delete(requests, ref)
    state = %State{state | requests: requests}
    json = encode_error(id, error)
    {:reply, {:text, json}, req, state}
  end
  def websocket_info({<<"subscribe.", type :: binary>> = cmd, reply}, req, state)
    when type in ["block", "transaction", "heartbeat"]  do
    json = encode_reply(cmd, reply)
    {:reply, {:text, json}, req, state}
  end

  def websocket_terminate(_any, _req, _state) do
    :ok
  end

  def terminate(_reason, _req, _state) do
    :ok
  end

  def handle_command(%{command: <<"subscribe.", type :: binary>>}, req, state)
    when type in ["block", "transaction", "heartbeat"] do
    true = :gproc.reg({:p, :l, "subscribe." <> type}, self)
    {:ok, req, state}
  end
  def handle_command(%{command: <<"subscribe.", type :: binary>>, params: params}, req, state)
    when type in ["utxo", "address"] do
    for item <- params do
      true = :gproc.reg({:p, :l, "subscribe." <> type <> "." <> item}, self)
    end
    {:ok, req, state}
  end
  def handle_command(%{command: command} = payload, req, state) do
    case find_module(command) do
      {:error, _reason} ->
        {:ok, req, state}
      {:ok, module} -> do_handle_command(module, payload, req, state)
    end
  end

  defp do_handle_command(module, %{id: id, params: params}, req, %{requests: requests} = state) do
    case module.transform_args(params) do
      {:ok, args} ->
        {:ok, ref} = send_command(module.command, args)
        requests = Map.put(requests, ref, %{id: id, module: module})
        {:ok, req, %State{state | requests: requests}}
      {:error, reason} ->
        # send error message
        IO.inspect {:error, module, params, reason}
        {:ok, req, state}
    end
  end

  defp send_command(command, args) do
    client = :pg2.get_closest_pid(Bitcoin.Voyager.Client)
    apply Libbitcoin.Client, command, [client] ++ args ++ [self]
  end

  defp encode_reply(id, reply) do
    {:ok, json} = JSX.encode(%{id: id, result: reply})
    json
  end

  defp encode_error(id, error) do
    {:ok, json} = JSX.encode(%{id: id, error: error})
    json
  end

  def find_module(name) do
    try do
      [type, endpoint] = String.split(name, ".") |> Enum.map(&Inflex.camelize(&1))
      module = Module.safe_concat([Bitcoin, Voyager, Handlers, type, endpoint<>"Handler"])
      {:ok, module}
    rescue
      ArgumentError ->
        {:error, "invalid module"}
    end
  end

end
