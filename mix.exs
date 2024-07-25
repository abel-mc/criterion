defmodule Criterion.MixProject do
  use Mix.Project

  def project do
    [
      app: :criterion,
      version: "0.1.12",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "A library to write tests bdd style.",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "Criterion",
      source_url: "https://github.com/abel-mc/criterion",
      homepage_url: "https://github.com/abel-mc/criterion",
      docs: [
        # The main page in the docs
        main: "readme",
        logo: "assets/logo.jpeg",
        extras: ["README.md"]
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:ex_doc, "~> 0.31", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README.md"
      ],
      maintainers: ["Abel Mesfin Cherinet"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/abel-mc/criterion"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
