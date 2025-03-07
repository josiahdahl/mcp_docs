defmodule MCPDocs.MixProject do
  use Mix.Project

  def project do
    [
      app: :mcp_docs,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "MCP server for querying Elixir project documentation",
      package: package(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {MCPDocs.Application, []},
      # Set CLI as the entry point for the executable
      env: [mcp_docs: [main_module: MCPDocs.CLI]]
    ]
  end

  # Add this to ensure the CLI module is used as the main entry point
  def cli do
    [
      default_task: "run",
      main: {MCPDocs.CLI, :main}
    ]
  end

  defp deps do
    [
      {:mcp_sse, "~> 0.1.0"},
      {:plug, "~> 1.14"},
      {:cors_plug, "~> 3.0"},
      {:bandit, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:styler, "~> 1.4", only: [:test, :dev], runtime: false}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/josiahdahl/mcp_docs"}
    ]
  end

  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_other), do: ["lib"]
end
