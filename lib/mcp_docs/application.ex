defmodule MCPDocs.Application do
  @moduledoc false
  use Application

  @impl Application
  def start(_type, _args) do
    Application.put_env(:mcp_sse, :mcp_server, MCPDocs.Server, persistent: true)
    children = List.flatten([bandit()])

    opts = [strategy: :one_for_one, name: MCPDocs.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def bandit do
    port = Application.get_env(:mcp_docs, :port, 9702)

    if Application.get_env(:mcp_docs, :start_server?, true) do
      [{Bandit, plug: MCPDocs.Router, port: port}]
    else
      []
    end
  end
end
