defmodule Qdrant.MixProject do
  use Mix.Project

  def project do
    [
      app: :qdrant,
      version: "0.1.18",
      elixir: "~> 1.20",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "Qdrant",
      package: package(),
      description: "Qdrant Elixir client",
      authors: ["Nikola (marinac-dev)"],
      source_url: "https://github.com/marinac-dev/qdrant",
      docs: [
        main: "readme",
        source_ref: "v0.1.18",
        extras: ["README.md", "CHANGELOG.md", "LICENSE"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Qdrant.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:finch, "~> 0.23"},
      {:tesla, "~> 1.21"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

  defp package() do
    [
      name: "qdrant",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      links: %{"GitHub" => "https://github.com/marinac-dev/qdrant"},
      licenses: ["MIT"],
      maintainers: ["Nikola (marinac-dev)"]
    ]
  end
end
