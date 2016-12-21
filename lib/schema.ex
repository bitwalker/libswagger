defmodule Swagger.Schema do
  @moduledoc """
  This module defines a struct which is a strongly typed representation
  of a Swagger specification document.
  """
  alias Swagger.Schema.{Utils, Endpoint, Security}

  defstruct info: %{},
    host: nil,
    base_path: nil,
    schemes: [],
    paths: %{},
    consumes: [],
    produces: [],
    security_definitions: %{},
    security: nil,
    properties: %{}

  def from_schema(schema) when is_map(schema) do
    case extract_paths(schema) do
      {:error, _} = err ->
        err
      paths ->
        res = %__MODULE__{}
        |> Map.put(:info, Map.get(schema, "info"))
        |> Map.put(:host, Map.get(schema, "host"))
        |> Map.put(:base_path, Map.get(schema, "basePath"))
        |> Map.put(:schemes, extract_schemes(schema))
        |> Map.put(:paths, paths)
        |> Map.put(:consumes, Utils.extract_media_types(schema, "consumes"))
        |> Map.put(:produces, Utils.extract_media_types(schema, "produces"))
        |> Map.put(:properties, Utils.extract_properties(schema))
        |> Map.put(:security_definitions, extract_security_defs(schema))
        apply_security(res, schema)
    end
  end

  @doc """
  Used by ex_json_schema for remote resolution of schemas
  """
  def resolve(url) do
    response = Tesla.get(url)
    Poison.decode!(response.body)
  end

  defp extract_schemes(%{"schemes" => []}), do: ["http"]
  defp extract_schemes(%{"schemes" => schemes}) when is_list(schemes) do
    schemes
  end
  defp extract_schemes(_), do: ["http"]

  defp extract_paths(%{"paths" => paths}) when is_map(paths) do
    Enum.reduce(paths, %{}, fn
      _, {:error, _} = err ->
        err
      {k, v}, acc ->
        case Endpoint.from_schema(k, v) do
          {:ok, e} -> Map.put(acc, k, e)
          {:error, _} = err -> err
        end
    end)
  end
  defp extract_paths(_), do: %{}

  defp extract_security_defs(%{"securityDefinitions" => security_defs}) when is_map(security_defs) do
    Enum.reduce(security_defs, %{}, fn {k, v}, acc ->
      Map.put(acc, k, Security.from_schema(k, v))
    end)
  end
  defp extract_security_defs(_), do: %{}

  defp apply_security(%__MODULE__{security_definitions: defs} = res, %{"security" => [sec]}) do
    case Map.get(defs, sec) do
      nil -> res
      sd  -> %{res | :security => sd}
    end
  end
  defp apply_security(res, _), do: res
end
