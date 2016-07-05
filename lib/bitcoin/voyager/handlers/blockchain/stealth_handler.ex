defmodule Bitcoin.Voyager.Handlers.Blockchain.StealthHandler do
  alias Bitcoin.Voyager.Util

  @moduledoc """
  """

  def command, do: :stealth

  def transform_args(%{height: height} = args) when is_binary(height) do
    transform_args(%{args | height: String.to_integer(height)})
  end
  def transform_args(%{filter: bits, height: height}) do
    {:ok, [bits, height]}
  end
  def transform_args(_params) do
    {:error, :invalid}
  end

  def transform_reply(matches) do
    transform_reply(matches, [])
  end

  def transform_reply([], acc) do
    {:ok, acc}
  end
  def transform_reply([%{address: _, ephemkey: _, tx_hash: _} = head|tail], acc) do
    row = Enum.map head, fn({key, value}) ->
      {:ok, hex_value} = Util.encode_hex(value)
      {key, hex_value}
    end
    transform_reply(tail, [row|acc])
  end
  def transform_reply(other, other2) do
    {:error, :invalid_reply}
  end

end

