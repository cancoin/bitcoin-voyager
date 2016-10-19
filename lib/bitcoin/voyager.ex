defmodule Bitcoin.Voyager do
  alias Bitcoin.Voyager
  require Logger

  @default_pool_args [size: 10, overflow: 20]

  def start(_type, _args) do
    case load_config do
      {:ok, config} ->
        write_pid!
        Logger.info "Starting Bitcoin Explorer on port #{config.port}"
        :ok = Bitcoin.Voyager.Cache.start_link
        {:ok, _} = :cowboy.start_http(:http, 100,
                                      [port: config.port],
                                      [env: [dispatch: dispatch(config)]])
        Voyager.Supervisor.start_link(config)
      :invalid_configuration ->
        Logger.error "Error starting Bitcoin Voyager server"
        exit(:invalid_configuration)
    end
  end

  def dispatch(_config) do
    :cowboy_router.compile([
      {:_, [ { '/api/v1/blockchain/last_height', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.LastHeightHandler] },
             { '/api/v1/blockchain/block_height/:hash', Voyager.RESTHandler, [ Voyager.Handlers.Blockchain.BlockHeightHandler] },
             { '/api/v1/blockchain/block_header/:height', Voyager.RESTHandler, [ Voyager.Handlers.Blockchain.BlockHeaderHandler] },
             { '/api/v1/blockchain/block_transaction_hashes/:hash', Voyager.RESTHandler, [ Voyager.Handlers.Blockchain.BlockTransactionHashesHandler] },
             { '/api/v1/blockchain/transaction/:hash', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.TransactionHandler] },
             { '/api/v1/blockchain/history/:address/:height', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.HistoryHandler] },
             { '/api/v1/blockchain/transaction_index/:hash', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.TransactionIndexHandler] },
             { '/api/v1/blockchain/spend/:hash/:index', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.SpendHandler] },
             { '/api/v1/blockchain/stealth/:filter/:height', Voyager.RESTHandler, [Voyager.Handlers.Blockchain.StealthHandler] },
             { '/api/v1/transaction_pool/transaction/:hash', Voyager.RESTHandler, [Voyager.Handlers.TransactionPool.TransactionHandler] },
             { '/api/v1/transaction_pool/validate', Voyager.RESTHandler, [Voyager.Handlers.TransactionPool.ValidateHandler] },
             { '/api/v1/address/history/:address/:height', Voyager.RESTHandler, [Voyager.Handlers.Address.HistoryHandler] },
             { '/api/v1/address/history2/:address/:count', Voyager.RESTHandler, [Voyager.Handlers.Address.History2Handler] },
             { '/api/v1/protocol/broadcast_transaction', Voyager.RESTHandler, [Voyager.Handlers.Protocol.BroadcastTransactionHandler] },
             { '/api/v1/protocol/total_connections', Voyager.RESTHandler, [Voyager.Handlers.Protocol.TotalConnectionsHandler] },
             { '/api/v1/wallet', Voyager.WalletHandler, [] },
             { '/api/v1/websocket', Voyager.WebSocketHandler, [] },
             {'/', :cowboy_static, {:priv_file, :bitcoin_voyager, 'web/build/assets/index.html'}},
             { '/assets/[...]', :cowboy_static, {:priv_dir, :bitcoin_voyager, 'web/build/assets'}}
           ] }
     ])
  end

  defp load_config do
    try do
      {:ok, uri}      = Application.fetch_env(:bitcoin_voyager, :uri)
      {:ok, port}     = Application.fetch_env(:bitcoin_voyager, :port)
      bind            = Application.get_env(:bitcoin_voyager, :bind, "127.0.0.1")
      domain          = Application.get_env(:bitcoin_voyager, :domain, :_)
      heartbeat_uri   = Application.get_env(:bitcoin_voyager, :heartbeat_uri, nil)
      block_uri       = Application.get_env(:bitcoin_voyager, :block_uri, nil)
      transaction_uri = Application.get_env(:bitcoin_voyager, :transaction_uri, nil)
      pool            = Application.get_env(:bitcoin_voyager, :pool, @default_pool_args)
      {:ok, %{
        port: port,
        bind: to_string(bind),
        domain: domain,
        pool: pool,
        uri: to_string(uri),
        heartbeat_uri: heartbeat_uri,
        block_uri: block_uri,
        transaction_uri: transaction_uri}}
    rescue
      MatchError -> :invalid_configuration
    end
  end

  def write_pid! do
    {:ok, pidfile} = :application.get_env(:bitcoin_voyager, :pidfile)
    :ok = File.write(pidfile, :os.getpid)
  end
end
