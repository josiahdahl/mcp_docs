defmodule MCPDocs.Server do
  @moduledoc false
  use MCPServer

  require Logger

  @protocol_version "2024-11-05"

  @impl MCPServer
  def handle_ping(request_id) do
    {:ok, %{jsonrpc: "2.0", id: request_id, result: "pong"}}
  end

  @impl MCPServer
  def handle_initialize(request_id, params) do
    Logger.info("Client initialization params: #{inspect(params, pretty: true)}")

    case validate_protocol_version(params["protocolVersion"]) do
      :ok ->
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             protocolVersion: @protocol_version,
             capabilities: %{
               tools: %{
                 listChanged: true
               }
             },
             serverInfo: %{
               name: "Your MCP Server",
               version: "0.1.0"
             }
           }
         }}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @impl MCPServer
  def handle_list_tools(request_id, _params) do
    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         tools: [
           %{
             name: "docs",
             description: "Lookup Elixir function documentation",
             inputSchema: %{
               type: "object",
               required: ["module", "function", "arity"],
               properties: %{
                 module: %{
                   type: "string",
                   description: "The module"
                 },
                 function: %{
                   type: "string",
                   description: "The function"
                 },
                 arity: %{
                   type: "integer",
                   description: "The arity"
                 }
               }
             },
             outputSchema: %{
               type: "object",
               required: ["output"],
               properties: %{
                 output: %{
                   type: "string",
                   description: "The full documentation for the module"
                 }
               }
             }
           },
           %{
             name: "upcase",
             description: "OPRSConverts text to uppercase",
             inputSchema: %{
               type: "object",
               required: ["text"],
               properties: %{
                 text: %{
                   type: "string",
                   description: "The text to convert to uppercase"
                 }
               }
             },
             outputSchema: %{
               type: "object",
               required: ["output"],
               properties: %{
                 output: %{
                   type: "string",
                   description: "The uppercase version of the input text"
                 }
               }
             }
           }
         ]
       }
     }}
  end

  @impl MCPServer
  def handle_call_tool(request_id, %{"name" => "upcase", "arguments" => %{"text" => text}} = params) do
    Logger.debug("Handling upcase tool call with params: #{inspect(params, pretty: true)}")

    {:ok,
     %{
       jsonrpc: "2.0",
       id: request_id,
       result: %{
         content: [
           %{
             type: "text",
             text: String.upcase(text)
           }
         ]
       }
     }}
  end

  def handle_call_tool(
        request_id,
        %{"name" => "docs", "arguments" => %{"module" => module, "function" => function, "arity" => arity}} = params
      ) do
    Logger.debug("Handling docs tool call with params: #{inspect(params, pretty: true)}")

    output = MCPDocs.Documentation.get_docs(module, function, arity)

    case output do
      %{
        type: :function,
        functions: [function]
      } ->
        {:ok,
         %{
           jsonrpc: "2.0",
           id: request_id,
           result: %{
             content: [
               %{
                 type: "text",
                 text: function.doc
               }
             ]
           }
         }}

      other ->
        Logger.error(inspect(other))

        {:error,
         %{
           jsonrpc: "2.0",
           id: request_id,
           error: %{
             code: -32_601,
             message: "Method not found",
             data: %{
               name: "docs"
             }
           }
         }}
    end
  end

  def handle_call_tool(request_id, %{"name" => unknown_tool} = params) do
    Logger.warning("Unknown tool called: #{unknown_tool} with params: #{inspect(params, pretty: true)}")

    {:error,
     %{
       jsonrpc: "2.0",
       id: request_id,
       error: %{
         code: -32_601,
         message: "Method not found",
         data: %{
           name: unknown_tool
         }
       }
     }}
  end
end
