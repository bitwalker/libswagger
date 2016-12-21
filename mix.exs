defmodule Swagger.Mixfile do
  use Mix.Project

  def project do
    [app: :libswagger,
     version: "0.1.0",
     elixir: "~> 1.3",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :poison, :yaml_elixir, :ex_json_schema, :tesla]]
  end

  defp deps do
    [{:poison, "~> 3.0"},
     {:tesla, "~> 0.5.2"},
     {:hackney, "~> 1.6", optional: true},
     {:yaml_elixir, "~> 1.1"},
     {:ex_json_schema, "~> 0.5"}]
  end
end
