defmodule BitcoinVoyager.Mixfile do
  use Mix.Project

  def project do
    [app: :bitcoin_voyager,
     version: "0.2.0",
     elixir: "~> 1.0",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps ++ deps(Mix.env)]
  end

  def application do
    [applications: [
      :logger, :exjsx,
      :gproc, :base58, :inflex,
      :ranch, :cowlib, :cowboy,
      :libbitcoin_client, :libbitcoin],
     mod: {Bitcoin.Voyager, []}]
 end

  defp deps do
    [
      {:exrm, "~> 1.0.8"},
      {:exjsx, "~> 3.2.0"},
      {:gproc, "~> 0.5.0"},
      {:inflex, "~> 1.5.0"},
      {:ranch, "~> 1.1.0", override: true, compile: gnu_make},
      {:cowlib, github: "ninenines/cowlib", override: true, ref: "master", compile: gnu_make},
      {:cowboy, github: "ninenines/cowboy", ref: "2.0.0-pre.3", compile: gnu_make},
      {:libbitcoin_client, github: "cancoin/elixir-libbitcoin-client"},
      {:libbitcoin, github: "cancoin/libbitcoin-nif"},
      {:base58, github: "cancoin/erl-base58"}
    ]
  end

  defp deps(:test) do
    [
      {:gun, github: "ninenines/gun", ref: "master"}
    ]
  end
  defp deps(_), do: []

  defp gnu_make do
    case System.cmd "uname", [] do
      {"FreeBSD\n",0} -> "gmake"
      _other -> "make"
    end
  end

end
