defmodule Swagger.Schema do
  @moduledoc """
  This module defines a struct which is a strongly typed representation
  of a Swagger specification document.
  """
  alias Swagger.Schema.{Utils, Endpoint, Security, Operation}

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

  @type t :: %__MODULE__{
    info: map(),
    host: String.t,
    base_path: String.t,
    schemes: [String.t],
    paths: map(),
    consumes: [String.t],
    produces: [String.t],
    security_definitions: %{String.t => Security.t},
    security: [String.t | {String.t, [String.t]}],
    properties: map()}

  use Swagger.Access

  def from_schema(schema) when is_map(schema) do
    case extract_paths(schema) do
      {:error, _} = err ->
        err
      paths ->
        %__MODULE__{}
        |> Map.put(:info, Map.get(schema, "info"))
        |> Map.put(:host, Map.get(schema, "host"))
        |> Map.put(:base_path, Map.get(schema, "basePath"))
        |> Map.put(:schemes, extract_schemes(schema))
        |> Map.put(:paths, paths)
        |> Map.put(:consumes, Utils.extract_media_types(schema, "consumes"))
        |> Map.put(:produces, Utils.extract_media_types(schema, "produces"))
        |> Map.put(:properties, Utils.extract_properties(schema))
        |> Map.put(:security_definitions, extract_security_defs(schema))
        |> apply_security(schema)
    end
  end

  @doc """
  Used by ex_json_schema for remote resolution of schemas
  """
  def resolve(url) do
    response = Tesla.get(url)
    Poison.decode!(response.body)
  end

  defp extract_schemes(%{"schemes" => schemes}) when is_list(schemes) do
    schemes
  end
  defp extract_schemes(_), do: []

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

  defp apply_security(%__MODULE__{security_definitions: defs} = res, %{"security" => security_reqs}) do
    case apply_security_requirements(defs, res, security_reqs) do
      {:error, _} = err ->
        err
      schema ->
        apply_operation_security(schema)
    end
  end
  defp apply_security(%__MODULE__{security_definitions: defs} = res, _) do
    defs
    |> apply_security_requirements(res, %{})
    |> apply_operation_security()
  end

  defp apply_operation_security(%__MODULE__{paths: paths} = schema),
    do: apply_operation_security(schema, Enum.into(paths, []))
  defp apply_operation_security(schema, []), do: schema
  defp apply_operation_security(_, {:error, _} = err), do: err
  defp apply_operation_security(schema, [{path, %Endpoint{operations: ops}}|rest]) do
    apply_operation_security(apply_operation_security(schema, path, Enum.into(ops, [])), rest)
  end
  defp apply_operation_security(_schema, _path, {:error, _} = err), do: err
  defp apply_operation_security(schema, _path, []), do: schema
  defp apply_operation_security(schema, path, [{name, %Operation{security: reqs} = op}|rest]) do
    case apply_security_requirements(schema.security_definitions, op, reqs) do
      {:error, _} = err ->
        err
      op2 ->
        schema2 = put_in(schema, [:paths, path, :operations, name], op2)
        apply_operation_security(schema2, path, rest)
    end
  end

  defp apply_security_requirements(security_definitions, obj, reqs) do
    security = Enum.reduce(reqs, [], fn
      _, {:error, _} = err ->
        err
      {req_name, []}, acc ->
        case Map.get(security_definitions, req_name) do
          nil   -> {:error, {:invalid_security, req_name, :definition_not_found}}
          _sdef -> [{req_name, []} | acc]
        end
      {req_name, desired_scopes}, acc ->
        case Map.get(security_definitions, req_name) do
          nil ->
            {:error, {:invalid_security, req_name, :definition_not_found}}
          %{scopes: scopes} ->
            cond do
              Enum.all?(desired_scopes, fn s -> s in scopes end) ->
                [{req_name, desired_scopes} | acc]
              :else ->
                invalid = Enum.reject(desired_scopes, fn s -> s in scopes end)
                {:error, {:invalid_security, req_name, {:invalid_scopes, invalid}}}
            end
        end
    end)
    %{obj | :security => security}
  end
end
