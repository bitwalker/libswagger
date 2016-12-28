defmodule Swagger.Schema.Security do
  @moduledoc """
  A Security struct defines the security requirements for an API, what type of security is
  applied, and how it should be applied in requests to the API.
  """
  alias Swagger.Schema.Utils
  alias __MODULE__

  @type t :: None.t
    | Basic.t
    | ApiKey.t
    | OAuth2Implicit.t
    | OAuth2Password.t
    | OAuth2Application.t
    | OAuth2AccessCode.t

  def from_schema(id, %{"type" => "basic"} = schema) when is_map(schema) do
    Security.Basic.from_schema(id, schema)
  end
  def from_schema(id, %{"type" => "apiKey"} = schema) when is_map(schema) do
    Security.ApiKey.from_schema(id, schema)
  end
  def from_schema(id, %{"type" => "oauth2"} = schema) when is_map(schema) do
    case schema["flow"] do
      "implicit"    -> Security.OAuth2Implicit.from_schema(id, schema)
      "password"    -> Security.OAuth2Password.from_schema(id, schema)
      "application" -> Security.OAuth2Application.from_schema(id, schema)
      "accessCode"  -> Security.OAuth2AccessCode.from_schema(id, schema)
      type          -> {:error, {:invalid_oauth_security_type, type}}
    end
  end

  defmodule None do
    defstruct id: "none",
      description: "no security",
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t}
  end

  defmodule Basic do
    defstruct id: nil,
      description: nil,
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
    end
  end

  defmodule ApiKey do
    defstruct id: nil,
      description: nil,
      name: nil,
      in: nil,
      properties: %{}

    @type in_type :: :header | :query
    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t,
                           name: String.t, in: in_type}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Map.put(:name, schema["name"])
      |> Map.put(:in, String.to_atom(schema["in"]))
    end
  end

  defmodule OAuth2Implicit do
    defstruct id: nil,
      description: nil,
      scopes: nil,
      authorization_url: nil,
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t,
                           scopes: String.t, authorization_url: String.t}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Map.put(:scopes, schema["scopes"])
      |> Map.put(:authorization_url, schema["authorizationUrl"])
    end
  end

  defmodule OAuth2Password do
    defstruct id: nil,
      description: nil,
      scopes: nil,
      token_url: nil,
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t,
                           scopes: String.t, token_url: String.t}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Map.put(:scopes, schema["scopes"])
      |> Map.put(:token_url, schema["tokenUrl"])
    end
  end

  defmodule OAuth2Application do
    defstruct id: nil,
      description: nil,
      scopes: nil,
      token_url: nil,
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t,
                           scopes: String.t, token_url: String.t}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Map.put(:scopes, schema["scopes"])
      |> Map.put(:token_url, schema["tokenUrl"])
    end
  end

  defmodule OAuth2AccessCode do
    defstruct id: nil,
      description: nil,
      scopes: nil,
      token_url: nil,
      authorization_url: nil,
      properties: %{}

    @type t :: %__MODULE__{id: String.t, description: String.t, properties: Map.t,
                           scopes: String.t, token_url: String.t, authorization_url: String.t}

    def from_schema(id, schema) when is_map(schema) do
      %__MODULE__{id: id}
      |> Map.put(:description, schema["description"])
      |> Map.put(:properties, Utils.extract_properties(schema))
      |> Map.put(:scopes, schema["scopes"])
      |> Map.put(:token_url, schema["tokenUrl"])
      |> Map.put(:authorization_url, schema["authorizationUrl"])
    end
  end

end
