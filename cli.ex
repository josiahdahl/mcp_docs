defmodule MCPDocs.CLI do
  @moduledoc """
  Command-line interface for MCPDocs.
  """
  
  @doc """
  Main entry point for the CLI application.
  """
  def main(args) do
    {opts, args, _} = OptionParser.parse(
      args,
      switches: [
        port: :integer,
        host: :string,
        project_path: :string,
        help: :boolean
      ],
      aliases: [
        p: :port,
        h: :host,
        d: :project_path,
        H: :help
      ]
    )
    
    if opts[:help] do
      display_help()
    else
      start_server(opts, args)
    end
    
    # Keep the process alive
    Process.sleep(:infinity)
  end
  
  defp start_server(opts, _args) do
    # Default to current directory if no project path is provided
    project_path = opts[:project_path] || File.cwd!()
    port = opts[:port] || 8080
    host = opts[:host] || "127.0.0.1"
    
    # Print banner
    IO.puts """
    
     __  __  ____ ____  ____                  
    |  \\/  |/ ___|  _ \\|  _ \\  ___   ___ ___ 
    | |\\/| | |   | |_) | | | |/ _ \\ / __/ __|
    | |  | | |___|  __/| |_| | (_) | (__\\__ \\
    |_|  |_|\\____|_|   |____/ \\___/ \\___|___/
                                             
    MCP Documentation Server - v#{Application.spec(:mcp_docs, :vsn)}
    Running on #{host}:#{port}
    Project path: #{project_path}
    
    Press Ctrl+C to exit
    """
    
    # Start the server
    case MCPDocs.start_server(port: port, host: host, project_path: project_path) do
      {:ok, _pid} ->
        IO.puts "Server started successfully"
      
      {:error, reason} ->
        IO.puts :stderr, "Failed to start server: #{inspect(reason)}"
        System.halt(1)
    end
  end
  
  defp display_help do
    IO.puts """
    MCPDocs - Model Context Protocol Documentation Server
    
    Usage:
      mcp_docs [options]
    
    Options:
      -p, --port PORT          Port to run the server on (default: 8080)
      -h, --host HOST          Host to bind to (default: 127.0.0.1)
      -d, --project_path PATH  Path to the Elixir project (default: current directory)
      -H, --help               Show this help message
    
    Examples:
      mcp_docs --port 9000
      mcp_docs --project_path /path/to/my/project
    """
    
    System.halt(0)
  end
end
