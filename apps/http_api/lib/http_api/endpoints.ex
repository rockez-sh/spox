defmodule HttpApi.Endpoints do
  alias Core.Utils
  use Plug.Router
  plug :match
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Poison
  plug :dispatch


  alias Core.ConfigService
  alias Core.SchemaService, as: SchemaSVC
  post "/api/cog" do
    case conn.body_params
    |> Map.fetch!("cog")
    |> Utils.atomize_map
    |> ConfigService.create do
      {:ok, cs} ->
        {:ok, cs |> ConfigService.as_json |> Poison.encode!}
      {:error, :validate_schema, error} ->
        {:malformed_data, response_error(:schema_error, error) |> Poison.encode! }
      _ -> {:server_error, "unknow error"}
    end |> handle_response(conn)
  end

  post "/api/sch" do
    case conn.body_params
    |> Map.fetch!("sch")
    |> Utils.atomize_map
    |> SchemaSVC.create do
      {:ok, schema} ->
        {:ok, schema
        |> SchemaSVC.as_json
        |> Poison.encode!}
      {:error, stage, message} ->
        {:malformed_data, response_error(:create_schema, stage, message)
        |> Poison.encode!}
    end |> handle_response(conn)
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

  defp response_error(:schema_error, :schema_not_found) do
    %{success: false, errors: %{schema: "not found"}}
  end

  defp response_error(:schema_error, errors) when is_list(errors) do
    %{success: false, schema_errors: errors |> schema_errors_to_list}
  end

  defp response_error(:create_schema, :validate_schema, message) do
    %{success: false, errors: %{value: message}}
  end
  defp response_error(:create_schema, :parsed_json, message) do
    %{success: false, errors: %{value: message}}
  end

  defp schema_errors_to_list(errors) do
    errors |> Enum.map(&schema_error_to_map/1)
  end

  defp schema_error_to_map(error) do
    {message, path} = error
    %{message: message, path: path}
  end
end