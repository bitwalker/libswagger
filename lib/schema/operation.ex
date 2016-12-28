defmodule Swagger.Schema.Operation do
  @moduledoc """
  An Operation defines a specific action one can take against an API.
  An Operation contains all of the information necessary to execute a request to
  perform that action, such as what parameters it requires, what content types it
  will accept and return, the specification of it's responses, what security it
  requires, and more.
  """

  alias Swagger.Schema.{Utils, Parameter}

  defstruct name: nil,
    tags: [],
    summary: nil,
    description: nil,
    id: nil,
    produces: [],
    consumes: [],
    parameters: %{},
    responses: %{},
    schemes: [],
    deprecated?: false,
    security: nil,
    properties: %{}

  @type mime_type :: String.t
  @type schema :: Map.t
  @type response :: :default | pos_integer

  @type t :: %__MODULE__{
    name: String.t, id: String.t,
    tags: [String.t],
    summary: String.t, description: String.t,
    produces: [mime_type], consumes: [mime_type],
    parameters: %{String.t => Parameter.t},
    responses: %{response => schema},
    schemes: [String.t],
    deprecated?: boolean,
    security: String.t,
    properties: Map.t
  }

  def from_schema(name, %{"operationId" => id} = op) do
    case extract_parameters(op) do
      {:error, _} = err ->
        err
      params ->
        res = %__MODULE__{name: name, id: id}
        |> Map.put(:tags, Map.get(op, "tags", []))
        |> Map.put(:summary, Map.get(op, "summary", "No summary"))
        |> Map.put(:description, Map.get(op, "description", "No description"))
        |> Map.put(:produces, Utils.extract_media_types(op, "produces"))
        |> Map.put(:consumes, Utils.extract_media_types(op, "consumes"))
        |> Map.put(:parameters, params)
        |> Map.put(:responses, extract_responses(op))
        |> Map.put(:schemes, Map.get(op, "schemes", []))
        |> Map.put(:deprecated?, Map.get(op, "deprecated", false))
        |> Map.put(:security, Map.get(op, "security", nil))
        |> Map.put(:properties, Utils.extract_properties(op))
        {:ok, res}
    end
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

  defp extract_responses(%{"responses" => responses}) when is_map(responses) do
    Enum.reduce(responses, %{}, fn
      {"default", %{"schema" => schema}}, acc ->
        Map.put(acc, :default, schema)
      {http_status, %{"schema" => schema}}, acc ->
        Map.put(acc, String.to_integer(http_status), schema)
      {http_status, _}, acc ->
        Map.put(acc, String.to_integer(http_status), nil)
    end)
  end
  defp extract_responses(_), do: %{}
end
