defmodule Swagger.Schema.Parameter do
  @moduledoc """
  A Parameter specifies the details about a value required by an
  Operation in order to be executed. It defines where it must be provided,
  such as in the path, headers, or body; it defines what type of value it is,
  how it is formatted, the name of the parameter, and more.
  """
  alias Swagger.Schema.Utils
  alias __MODULE__

  @type t :: BodyParam.t
    | HeaderParam.t
    | PathParam.t
    | QueryParam.t
    | FormDataParam.t

  def from_schema(schema) when is_map(schema) do
    case do_from_schema(schema) do
      {:error, _} = err -> err
      p -> {:ok, p}
    end
  end

  defp do_from_schema(%{"name" => name, "in" => "body"} = schema) do
    Parameter.BodyParam.from_schema(name, schema)
  end
  defp do_from_schema(%{"name" => name, "in" => "header"} = schema) do
    Parameter.HeaderParam.from_schema(name, schema)
  end
  defp do_from_schema(%{"name" => name, "in" => "path"} = schema) do
    Parameter.PathParam.from_schema(name, schema)
  end
  defp do_from_schema(%{"name" => name, "in" => "query"} = schema) do
    Parameter.QueryParam.from_schema(name, schema)
  end
  defp do_from_schema(%{"name" => name, "in" => "formdata"} = schema) do
    Parameter.FormDataParam.from_schema(name, schema)
  end
  defp do_from_schema(%{"name" => name, "in" => in_type}) do
    {:error, {:invalid_parameter_in_type, in_type, name}}
  end

  defmodule Primitive do
    defstruct type: nil,
      format: nil,
      items: [],
      collection_format: :csv,
      default: nil,
      maximum: nil,
      minimum: nil,
      exclusive_maximum?: false,
      exclusive_minimum?: false,
      max_length: nil,
      min_length: nil,
      pattern: nil,
      max_items: nil,
      min_items: nil,
      unique_items?: false,
      enum: nil,
      multiple_of: nil

    @type primitive_type :: :string | :number | :integer | :boolean | :array
    @type collection_format :: :csv | :ssv | :tsv | :pipes
    @type t :: %__MODULE__{
      type: primitive_type,
      format: String.t,
      items: [__MODULE__.t],
      collection_format: collection_format,
      default: term,
      maximum: number,
      minimum: number,
      exclusive_maximum?: boolean,
      exclusive_minimum?: boolean,
      max_length: pos_integer,
      min_length: non_neg_integer,
      pattern: String.t,
      max_items: pos_integer,
      min_items: non_neg_integer,
      unique_items?: boolean,
      enum: [primitive_type],
      multiple_of: pos_integer
    }

    use Swagger.Access

    def from_schema(%{"type" => type} = schema) when type in ["number", "integer"] do
      %__MODULE__{type: String.to_atom(type)}
      |> Map.put(:format, schema["format"])
      |> Map.put(:default, schema["default"])
      |> Map.put(:maximum, schema["maximum"])
      |> Map.put(:minimum, schema["minimum"])
      |> Map.put(:exclusive_maximum?, schema["exclusiveMaximum"])
      |> Map.put(:exclusive_minimum, schema["exclusiveMinimum"])
      |> Map.put(:multiple_of, schema["multiple_of"])
    end
    def from_schema(%{"type" => "string"} = schema) do
      %__MODULE__{type: :string}
      |> Map.put(:default, schema["default"])
      |> Map.put(:max_length, schema["maxLength"])
      |> Map.put(:min_length, schema["minLength"])
      |> Map.put(:pattern, schema["pattern"])
      |> Map.put(:enum, schema["enum"])
    end
    def from_schema(%{"type" => "boolean"} = schema) do
      %__MODULE__{type: :boolean}
      |> Map.put(:default, schema["default"])
    end
    def from_schema(%{"type" => "array"} = schema) do
      %__MODULE__{type: :array}
      |> Map.put(:items, Enum.map(schema["items"] || [], &from_schema/1))
      |> Map.put(:collection_format, schema["collectionFormat"])
      |> Map.put(:default, schema["default"])
      |> Map.put(:max_length, schema["maxLength"])
      |> Map.put(:min_length, schema["minLength"])
      |> Map.put(:max_items, schema["maxItems"])
      |> Map.put(:min_items, schema["minItems"])
      |> Map.put(:unique_items?, schema["uniqueItems"])
    end
    def from_schema(%{"type" => type}) do
      {:error, {:invalid_primitive_type, type}}
    end
  end

  defmodule BodyParam do
    defstruct name: nil,
      description: nil,
      required?: false,
      schema: nil,
      properties: %{}

    @type t :: %__MODULE__{name: String.t, description: String.t, required?: boolean, schema: Map.t, properties: Map.t}

    use Swagger.Access

    def from_schema(name, schema) when is_map(schema) do
      %__MODULE__{name: name}
      |> Map.put(:description, schema["description"])
      |> Map.put(:required?, schema["required"])
      |> Map.put(:schema, schema["schema"])
      |> Map.put(:properties, Utils.extract_properties(schema))
    end
  end

  defmodule HeaderParam do
    defstruct name: nil,
      description: nil,
      required?: false,
      spec: nil,
      properties: %{}

    @type t :: %__MODULE__{name: String.t, description: String.t, required?: boolean, spec: Primitive.t, properties: Map.t}

    use Swagger.Access

    def from_schema(name, schema) when is_map(schema) do
      %__MODULE__{name: name}
      |> Map.put(:description, schema["description"])
      |> Map.put(:required?, schema["required"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Parameter.apply_spec(schema)
    end
  end

  defmodule QueryParam do
    defstruct name: nil,
      description: nil,
      required?: false,
      allow_empty?: false,
      spec: nil,
      properties: %{}

    @type t :: %__MODULE__{name: String.t, description: String.t, required?: boolean, allow_empty?: boolean,
                           spec: Primitive.t, properties: Map.t}

    use Swagger.Access

    def from_schema(name, schema) when is_map(schema) do
      %__MODULE__{name: name}
      |> Map.put(:description, schema["description"])
      |> Map.put(:required?, schema["required"])
      |> Map.put(:allow_empty?, schema["allowEmpty"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Parameter.apply_spec(schema)
    end
  end

  defmodule FormDataParam do
    defstruct name: nil,
      description: nil,
      required?: false,
      allow_empty?: false,
      spec: nil,
      properties: %{}

    @type t :: %__MODULE__{name: String.t, description: String.t, required?: boolean, allow_empty?: boolean,
                           spec: Primitive.t, properties: Map.t}

    use Swagger.Access

    def from_schema(name, schema) when is_map(schema) do
      %__MODULE__{name: name}
      |> Map.put(:description, schema["description"])
      |> Map.put(:required?, schema["required"])
      |> Map.put(:allow_empty?, schema["allowEmpty"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Parameter.apply_spec(schema)
    end
  end

  defmodule PathParam do
    defstruct name: nil,
      description: nil,
      required?: false,
      spec: nil,
      properties: %{}

    @type t :: %__MODULE__{name: String.t, description: String.t, required?: boolean, spec: Primitive.t, properties: Map.t}

    use Swagger.Access

    def from_schema(name, schema) when is_map(schema) do
      %__MODULE__{name: name}
      |> Map.put(:description, schema["description"])
      |> Map.put(:required?, schema["required"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Parameter.apply_spec(schema)
    end
  end

  @doc false
  def apply_spec(param, schema) when is_map(schema) do
    case Primitive.from_schema(schema) do
      {:error, _} = err ->
        err
      p -> Map.put(param, :spec, p)
    end
  end

end
