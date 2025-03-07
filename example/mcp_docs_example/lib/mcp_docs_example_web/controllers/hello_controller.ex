defmodule McpDocsExampleWeb.HelloController do
  use McpDocsExampleWeb, :controller

  @doc """
  Just an example controller. It will return whatever query parameters you give it as JSON
  """
  def index(conn, _params) do
    conn
    |> fetch_query_params()
    |> then(fn conn -> json(conn, conn.query_params) end)
  end
end
