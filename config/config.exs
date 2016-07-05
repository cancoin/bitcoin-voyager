use Mix.Config

config :bitcoin_voyager,
  port: 9090,
  bind: "0.0.0.0",
  uri: "tcp://voyager-api.cancoin.co:9091",
  heartbeat_uri: "tcp://voyager-api.cancoin.co:9092",
  block_uri: "tcp://voyager-api.cancoin.co:9093",
  transaction_uri: "tcp://voyager-api.cancoin.co:9094",
  pool: [size: 4],
  pidfile: "/tmp/bitcoin_voyager.pid"

config :sasl,
  errlog_type: :error

import_config "config.#{Mix.env}.exs"
