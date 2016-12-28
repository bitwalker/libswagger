defmodule Swagger.Access do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      @behaviour Access

      @doc false
      def fetch(%__MODULE__{} = s, key), do: Map.fetch(s, key)
      @doc false
      def get(%__MODULE__{} = s, key, default), do: Map.get(s, key, default)
      @doc false
      def get_and_update(%__MODULE__{} = s, key, fun), do: Map.get_and_update(s, key, fun)
      @doc false
      def pop(%__MODULE__{} = s, key), do: Map.pop(s, key)
    end
  end
end
