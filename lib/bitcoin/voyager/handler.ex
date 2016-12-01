defmodule Bitcoin.Voyager.Handler do

  defmacro __using__(_mod) do
    quote location: :keep do

      def command, do: throw(:not_implimented)

      def transform_args(args), do: throw(:not_implimented)

      def transform_reply(reply), do: throw(:not_implimented)

      def cache_ttl, do: 0

      def cache_key(params), do: ""

      def cache_name, do: nil

      def cache_serialize(value) when is_integer(value) do
        :binary.encode_unsigned(value)
      end
      def cache_serialize(value), do: value

      def cache_deserialize(value), do: value

      defoverridable [ command: 0, transform_args: 1, transform_reply: 1,
                       cache_ttl: 0, cache_name: 0, cache_key: 1,
                       cache_serialize: 1, cache_deserialize: 1]
    end
  end

end
