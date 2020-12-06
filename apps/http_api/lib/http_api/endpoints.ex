defmodule HttpApi.Endpoints do
  use Plug.Router
  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison
  plug :dispatch


  post "/api/cog" do
    {:ok, "OK"}
    |> handle_response(conn)
  end


  match _ do
    send_resp(conn, 404, "Page not found")
  end

  defp handle_response(response, conn) do

    # The service will always return a response that follow this pattern: {:code, :response}.
    # We will use the code to determine whether a request has been successfully treated or not.
    %{code: code, message: message} =
      case response do
        {:ok, message} -> %{code: 200, message: message}
        {:not_found, message} -> %{code: 404, message: message}
        {:malformed_data, message} -> %{code: 400, message: message}
        {:server_error, _} -> %{code: 500, message: "An error occurred internally"}
      end

    conn |> send_resp(code, message)
  end
end