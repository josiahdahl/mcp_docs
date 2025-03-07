# McpDocs

Provide documentation about your Elixir project's functions and functions of dependencies to an LLM through an SSE MCP server.

See [the example project](./example/mcp_docs_example) for more information.

This code was written in part by Claude Sonnet 3.5

## Installation

```elixir
def deps do
  [
    {:mcp_docs, github: "josiahdahl/mcp_docs", runtime: false, only: [:test, :dev]}
  ]
end
```

## Usage

```sh
# Start the SSE server on the default port of 9702
mix mcp_docs.start
```

```sh
# Start on a specific port
mix mcp_docs.start --port 1234
```

You can also run with `iex -S mix mcp_docs.start` to allow for manual recompiling of code.

You can use `npx @modelcontextprotocol/inspector` to try it out on your code base.

## Roadmap

- [ ] Automatically recompile on changes
- [ ] Look up module documentation
- [ ] Look up callback documentation

