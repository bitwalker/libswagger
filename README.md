# libswagger

This library provides a strongly typed representation of Swagger specification documents,
and an API for parsing to that representation from YAML or JSON, from a path or from a binary.

It automatically resolves remote schemas, using an HTTP client library of your choice via the
[Tesla](https://github.com/teamon/tesla) library.

## Basic Usage

Given a simple Swagger specification in YAML form, you can generate it's representation like so:

```elixir
Swagger.parse_file("myschema.yaml")

# or..

Swagger.parse_yaml(File.read!("myschema.yaml"))
```

The filetype is determined by the extension when using `parse_file/1`, otherwise you need to tell
`libswagger` the parser to use with either `parse_yaml/1` or `parse_json/1`.

The end result is a struct which looks something like the following:

```elixir
%Swagger.Schema{
  :info => %{"title" => "Key-Value Store", "version" => "0.2"},
  :host => "kv-service:8080",
  :schemes => ["http", "https"],
  :consumes => ["application/json"],
  :produces => ["application/json"],
  :paths => %{
    "/solution/{solution_id}" => %Swagger.Schema.Endpoint{
      :operations => %{
        :get => %Swagger.Schema.Operation{
          :id => "info",
          :responses => %{200 => _}
        }
      },
      :parameters => %{
        "solution_id" => %Swagger.Schema.Parameter.PathParam{
          :required? => true, 
          :spec => %{:type => :string, :pattern => "^[a-zA-Z0-9]+$"}}
      }
    }
}}
```

## License

MIT
