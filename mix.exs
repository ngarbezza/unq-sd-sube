defmodule Sube.MixProject do
  use Mix.Project

  def project do
    [
      app: :sube,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:credo, "~> 0.8.8", only: :dev, runtime: false},
      {:uuid, "~> 1.1"},
      {:ex_matchers, "~> 0.1.3", only: :test},
      {:amnesia, "~> 0.2.0"}
    ]
  end
end
