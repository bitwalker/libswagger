defmodule Swagger do
  @moduledoc File.read!(Path.join([__DIR__, "..", "README.md"]))

  alias Swagger.{Parser, Schema}

  @doc """
  Parse a Swagger specification from the given path, and return the expanded specification.
  """
  @spec parse_file(String.t) :: {:ok, Schema.t} | {:error, term}
  def parse_file(path) when is_binary(path) do
    Parser.parse(path)
  end

  @doc """
  Parse a Swagger specification from the given JSON binary, and return the expanded specification.
  """
  @spec parse_json(binary) :: {:ok, Schema.t} | {:error, term}
  def parse_json(json) do
    Parser.parse_json(json)
  end

  @doc """
  Parse a Swagger specification from the given YAML binary, and return the expanded specification.
  """
  @spec parse_yaml(binary) :: {:ok, Schema.t} | {:error, term}
  def parse_yaml(yaml) do
    Parser.parse_yaml(yaml)
  end
end
