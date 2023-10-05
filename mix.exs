defmodule CredoBinaryPatterns.MixProject do
  use Mix.Project

  @version "0.2.3"
  @source_url "https://github.com/smartrent/credo_binary_patterns"

  def project do
    [
      app: :credo_binary_patterns,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      docs: docs(),
      dialyzer: dialyzer(),
      deps: deps(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.build": :docs,
        "hex.publish": :docs,
        credo: :test,
        dialyzer: :test
      }
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:credo, "~> 1.6"},
      {:dialyxir, "~> 1.1", only: :test, runtime: false},
      {:ex_doc, "~> 0.22", only: :docs, runtime: false}
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "CHANGELOG.md",
        "README.md"
      ]
    ]
  end

  defp description do
    "Binary pattern checks for Credo"
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"Github" => @source_url}
    ]
  end

  defp dialyzer() do
    [
      flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
    ]
  end
end
