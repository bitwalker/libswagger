defmodule SwaggerParserTests do
  use ExUnit.Case, async: true

  alias Swagger.Schema
  alias Swagger.Schema.{Endpoint, Operation, Parameter}

  @keystore_example Path.join([__DIR__, "schemas", "keystore_example.yaml"])

  test "can parse valid swagger spec" do
    {:ok, schema} = Swagger.parse_file(@keystore_example)
    assert %Schema{
      :info => %{"title" => "Key-Value Store", "version" => "0.2"},
      :host => "kv-service:8080",
      :schemes => ["http", "https"],
      :consumes => ["application/json"],
      :produces => ["application/json"],
      :paths => %{
        "/solution/{solution_id}" => %Endpoint{
          :operations => %{
            :get => %Operation{
              :id => "info",
              :responses => %{200 => _}
            }
          },
          :parameters => %{
            "solution_id" => %Parameter.PathParam{:required? => true, :spec => %{:type => :string, :pattern => "^[a-zA-Z0-9]+$"}}
          }
        }
      }} = schema
  end
end
