defmodule Swagger.Schema.Utils do
  @moduledoc false

  @doc """
  Extracts vendor extensions (properties) from a schema.
  """
  def extract_properties(schema) when is_map(schema) do
    Enum.reduce(schema, %{}, fn
      {"x-" <> k, v}, acc ->
        Map.put(acc, "x-#{k}", v)
      {_k, _v}, acc ->
        acc
    end)
  end

  @doc """
  Extracts media types from the given schema located under the provided key
  """
  def extract_media_types(schema, key) do
    case schema do
      %{^key => types} when is_list(types) -> types
      _ -> []
    end
  end
end
