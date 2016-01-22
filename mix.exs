defmodule Keelless.Mixfile do
  use Mix.Project

  def project do
    [
      app: :keelless,
      version: "0.1.0",
      elixir: "~> 1.1",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      description: description,
      package: package,
      deps: deps
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :httpoison, :poison]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:poison, "~> 1.5"},
      {:hackney, "1.4.4"}, # force fixed hackney compile error
      {:httpoison, "~> 0.8.0"}
    ]
  end

  defp description do
    """
    Keen IO API for Elixir.
    """
  end

  defp package do
    [
      maintainers: ["hpyhacking"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/hpyhacking/keelless"}
    ]
  end
end
