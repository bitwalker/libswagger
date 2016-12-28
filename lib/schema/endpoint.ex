defmodule Swagger.Schema.Endpoint do
  @moduledoc """
  An Endpoint is defined as a single URI defining one or more Operations which
  are distinguished by the HTTP method used to call them. An Endpoint can define
  parameters which apply to all operations it contains.

  Using a brief example, `/api/v1/users` represents a URI for an Endpoint, which may expose
  one or more Operations, for instance the ability to create users via `POST` request. The
  Endpoint is the specification of what Operations are available, what parameters apply globally
  to all Operations, and additional vendor metadata.
  """

  alias Swagger.Schema.{Operation, Parameter, Utils}

  defstruct name: nil,
    route_pattern: nil,
    parameters: %{},
    operations: %{},
    properties: %{}

  @type t :: %__MODULE__{name: String.t,
                         parameters: %{String.t => Parameter.t},
                         operations: %{String.t => Operation.t},
                         properties: Map.t}

  use Swagger.Access

  def from_schema(path, schema) when is_map(schema) do
    case extract_parameters(schema) do
      {:error, _} = err ->
        err
      params ->
        case extract_operations(schema) do
          {:error, _} = err ->
            err
          ops ->
            endpoint = %__MODULE__{
              name: path,
              parameters: params,
              operations: ops,
              properties: Utils.extract_properties(schema)}
            route_pattern = Regex.compile!(construct_route_pattern(endpoint))
            {:ok, %{endpoint | route_pattern: route_pattern}}
        end
    end
  end

  defp construct_route_pattern(%__MODULE__{name: path, parameters: params}) do
    Enum.reduce(params, path, fn
      {k, %Parameter.PathParam{spec: %{pattern: p}}}, acc when is_binary(p) ->
        pattern = p
        |> String.trim_leading("^")
        |> String.trim_trailing("$")
        Regex.replace(~r/\{#{k}\}/, acc, "#{pattern}")
      {k, %Parameter.PathParam{spec: %{pattern: nil, type: :string}}}, acc ->
        Regex.replace(~r/\{#{k}\}/, acc, "[^/]+")
      {k, %Parameter.PathParam{spec: %{pattern: nil, type: :number}}}, acc ->
        Regex.replace(~r/\{#{k}\}/, acc, "[0-9]+(\.[0-9]+)?")
      {k, %Parameter.PathParam{spec: %{pattern: nil, type: :integer}}}, acc ->
        Regex.replace(~r/\{#{k}\}/, acc, "[0-9]+")
      {k, %Parameter.PathParam{spec: %{pattern: nil, type: :boolean}}}, acc ->
        Regex.replace(~r/\{#{k}\}/, acc, "true|false")
      {k, %Parameter.PathParam{spec: %{pattern: nil, type: type}}}, _acc ->
        raise "invalid parameter type '#{type}' for path parameter '#{k}'"
      {_k, _v}, acc ->
        acc
    end)
  end

  defp extract_parameters(%{"parameters" => parameters}) when is_list(parameters) do
    Enum.reduce(parameters, %{}, fn
      _, {:error, _} = err ->
        err
      p, acc ->
        case Parameter.from_schema(p) do
          {:error, _} = err ->
            err
          {:ok, param} ->
            Map.put(acc, param.name, param)
        end
    end)
  end
  defp extract_parameters(_), do: %{}

  @http_methods ["get", "post", "put", "patch", "delete", "options", "head"]
  defp extract_operations(schema) when is_map(schema) do
    Enum.reduce(schema, %{}, fn
      _, {:error, _} = err ->
        err
      {name, op_schema}, acc when name in @http_methods ->
        case Operation.from_schema(name, op_schema) do
          {:error, _} = err ->
            err
          {:ok, op} ->
            Map.put(acc, String.to_atom(name), op)
        end
      _, acc ->
        acc
    end)
  end
  defp extract_operations(_), do: %{}
end
