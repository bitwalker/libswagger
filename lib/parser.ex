defmodule Swagger.Parser do
  @moduledoc """
  This module is responsible for parsing Swagger definition files
  into a structure we can use elsewhere.
  """

  @doc """
  Given a path to a file, checks to see if the file extension is a parseable
  type, and if so, parses it and returns the parsed structure.

  It raises on error.
  """
  alias Swagger.Schema

  def parse(path) do
    case Path.extname(path) do
      ".json" ->
        with {:ok, json} <- File.read(path),
          do: parse_json(json)
      ".yaml" ->
        with {:ok, yaml} <- File.read(path),
          do: parse_yaml(yaml)
      ext ->
        raise "Unsupported file type: #{ext}"
    end
  end

  @doc """
  Parses the given binary as JSON
  """
  def parse_json(json) do
    with {:ok, parsed} <- Poison.decode(json),
      do: {:ok, parsed |> expand() |> to_struct()}
  end

  @doc """
  Parses the given binary as YAML
  """
  def parse_yaml(yaml) do
    spec = yaml
    |> YamlElixir.read_from_string(yaml)
    |> stringify_keys()
    |> expand()
    |> to_struct()
    {:ok, spec}
  end

  defp stringify_keys(nil), do: %{}
  defp stringify_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn
      {k, v}, acc when is_binary(k) -> Map.put(acc, k, stringify_keys(v))
      {k, v}, acc -> Map.put(acc, ~s(#{k}), stringify_keys(v))
    end)
  end
  defp stringify_keys(val), do: val

  defp expand(map) when is_map(map) do
    swagger = ExJsonSchema.Schema.resolve(map)
    expand(swagger, swagger.schema)
  end

  defp expand(swagger, %{"$ref" => ref_schema} = schema) do
    ref = ExJsonSchema.Schema.get_ref_schema(swagger, ref_schema)
    schema
    |> Map.delete("$ref")
    |> Map.merge(expand(swagger, ref))
  end
  defp expand(swagger, schema) when is_map(schema) do
    Enum.reduce(schema, %{}, fn {k, v}, acc ->
      Map.put(acc, k, expand(swagger, v))
    end)
  end
  defp expand(swagger, list) when is_list(list) do
    Enum.map(list, &expand(swagger, &1))
  end
  defp expand(_swagger, value), do: value

  defp to_struct(swagger) do
    Schema.from_schema(swagger)
  end
end
