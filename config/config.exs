import Config

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:module]

# Configure the MCP Server
config :mcp_sse, :mcp_server, MCPDocs.Server

# Configure MIME types for SSE
config :mime, :types, %{
  "text/event-stream" => ["sse"]
}

import_config "#{config_env()}.exs"
