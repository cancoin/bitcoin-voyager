defmodule Bitcoin.Voyager.Util do
  def decode_hex(arg_hex) do
    case arg_hex |> String.downcase |> Base.decode16(case: :lower) do
      {:ok, arg} ->
        {:ok, [arg]}
      :error ->
        {:ok, json} = JSX.encode(%{status: :fail, message: "Invalid base16"})
        {:error, json}
    end
  end

  def encode_hex(arg) when is_binary(arg) do
    {:ok, Base.encode16(arg, case: :lower)}
  end

  def encode_hex(arg) when is_list(arg) do
    hex_arg = Enum.map(arg, &Base.encode16(&1, case: :lower))
    {:ok, hex_arg}
  end

  def encode_hex(arg) when is_map(arg) do
    Enum.map arg, fn({key, value}) ->
      {:ok, hex_value} = encode_hex(value)
      {key, hex_value}
    end
  end

  def encode_hex(arg), do: arg

  def atomify(atom) when is_atom(atom), do: atom
  def atomify(bin) when is_binary(bin), do: String.to_atom(bin)
  def atomify(map) when is_map(map) do
    Map.to_list(map) |> Enum.map(fn
      ({k,v}) when is_map(v) -> {atomify(k), atomify(v)}
      ({k,v}) -> {String.to_atom(k), v}
    end) |> Enum.into(%{})
  end
end
