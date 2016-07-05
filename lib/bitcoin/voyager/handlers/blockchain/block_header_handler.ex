defmodule Bitcoin.Voyager.Handlers.Blockchain.BlockHeaderHandler do

  def command, do: :block_header

  def transform_args(%{height: height}) when is_binary(height) do
    {:ok, [:erlang.binary_to_integer(height, 10)]}
  end
  def transform_args(%{height: height}) when is_integer(height) do
    {:ok, [height]}
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(header) do
    case parse_block_header(header) do
      {:ok, header_map} -> {:ok, %{block_header: header_map}}
      {:error, error} -> {:error, error}
    end
  end

  defp parse_block_header(header) do
    header = :libbitcoin.header_decode(header)
    {:ok, header}
  end
  defp parse_block_header(_) do
    {:error, :invalid}
  end

end
