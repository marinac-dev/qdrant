defmodule Qdrant.MixProject do
  use Mix.Project

  def project do
    [
      app: :qdrant,
      version: "0.0.7",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Qdrant",
      package: package(),
      description: "Qdrant Elixir client",
      authors: ["Nikola (marinac-dev)"],
      source_url: "https://github.com/marinac-dev/qdrant",
      docs: [
        main: "readme",
        source_ref: "master",
        extras: ["README.md", "CHANGELOG.md", "LICENSE"]
      ]
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
      {:tesla, "~> 1.5"},
      {:jason, "~> 1.4"},
      {:mox, "~> 1.0"}
    ]
  end

  defp package() do
    [
      name: "qdrant",
      files: ~w(lib .formatter.exs mix.exs README* LICENSE* CHANGELOG* lib),
      links: %{"GitHub" => "https://github.com/marinac-dev/qdrant"},
      licenses: ["MIT"],
      maintainers: ["Nikola (marinac-dev)"]
    ]
  end
end
