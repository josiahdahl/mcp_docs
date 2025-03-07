defmodule Mix.Tasks.McpDocs.Start do
  @moduledoc """
  Start the McpDocs SSE Server

  ## Options

  --port - Default: 9702
  """
  use Mix.Task

  @impl Mix.Task
  def run(args) do
    {opts, _rest} = OptionParser.parse!(args, strict: [port: :integer])

    Application.put_env(:mcp_sse, :mcp_server, MCPDocs.Server, persistent: true)
    Application.put_env(:mcp_docs, :port, Keyword.get(opts, :port, 9702), persistent: true)
    {:ok, _apps} = Application.ensure_all_started(:mcp_docs)

    Mix.Tasks.Run.run(run_args())
  end

  defp iex_running? do
    Code.ensure_loaded?(IEx) and IEx.started?()
  end

  defp run_args do
    if iex_running?(), do: [], else: ["--no-halt"]
  end
end
