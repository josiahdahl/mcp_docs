defmodule McpDocsExampleWeb.Router do
  use McpDocsExampleWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", McpDocsExampleWeb do
    pipe_through :api

    get "/hello", HelloController, :index
  end
end
