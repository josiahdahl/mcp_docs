defmodule MCPDocs.Router do
  use Plug.Router

  require Logger

  plug CORSPlug

  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["text/*"],
    json_decoder: Jason

  plug :match
  plug :ensure_session_id
  plug :dispatch

  # Middleware to ensure session ID exists
  def ensure_session_id(conn, _opts) do
    case get_session_id(conn) do
      nil ->
        # Generate a new session ID if none exists
        session_id = generate_session_id()
        %{conn | query_params: Map.put(conn.query_params, "sessionId", session_id)}

      _session_id ->
        conn
    end
  end

  # Helper to get session ID from query params
  defp get_session_id(conn) do
    conn.query_params["sessionId"]
  end

  # Generate a unique session ID
  defp generate_session_id do
    Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end

  forward "/sse", to: SSE.ConnectionPlug
  forward "/message", to: SSE.ConnectionPlug

  match _ do
    send_resp(conn, 404, "Not found")
  end
end
