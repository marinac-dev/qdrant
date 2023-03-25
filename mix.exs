defmodule Qdrant.MixProject do
  use Mix.Project

  def project do
    [
      app: :qdrant,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Qdrant",
      package: package(),
      description: description(),
      source_url: "https://github.com/marinac-dev/qdrant"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29.3"},
      {:tesla, "~> 1.5"}
    ]
  end

  defp description do
    "Qdrant Elixir client"
  end

  defp package() do
    [
      name: "qdrant",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* lib),
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/marinac-dev/qdrant"}
    ]
  end
end
