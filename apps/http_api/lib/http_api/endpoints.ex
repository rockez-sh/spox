defmodule HttpApi.Endpoints do
  alias Core.Utils
  use Plug.Router
  plug CORSPlug
  plug Plug.Logger, log: :debug
  plug :match
  plug Plug.Parsers, parsers: [:json], json_decoder: Poison
  plug :dispatch

  alias Core.ConfigService
  alias Core.SchemaService
  alias Core.CollectionService
  alias Core.Utils.EctoError

  post "/api/cog" do
    case conn.body_params
    |> Map.fetch!("cog")
    |> Utils.atomize_map
    |> ConfigService.create do
      {:ok, cs} ->
        {:ok, cs |> ConfigService.as_json |> Poison.encode!}
      {:error, stage, error} ->
        {:malformed_data, response_error(:create_cog, stage, error) |> Poison.encode! }
      _ -> {:server_error, "unknow error"}
    end |> handle_response(conn)
  end

  post "/api/sch" do
    case conn.body_params
    |> Map.fetch!("sch")
    |> Utils.atomize_map
    |> SchemaService.create do
      {:ok, schema} ->
        {:ok, schema
        |> SchemaService.as_json
        |> Poison.encode!}
      {:error, stage, message} ->
        {:malformed_data, response_error(:create_schema, stage, message)
        |> Poison.encode!}
    end |> handle_response(conn)
  end

  get "/api/sch/:name" do
    %{"name" => sch_name} = conn.params
    case SchemaService.find(sch_name) do
      nil -> {:not_found, %{success: false, message: "cannot find Schema with name #{sch_name}"} |> Poison.encode!}
      result -> {:ok, %{data: result |> SchemaService.as_json} |> Poison.encode!}
    end |> handle_response(conn)
  end

  post "/api/col" do
    case conn.body_params
    |> Map.fetch!("col")
    |> Utils.atomize_map
    |> CollectionService.create do
      {:ok, collection} -> {:ok, collection |> CollectionService.as_json |> Poison.encode!}
      {:error, cs} -> {:malformed_data, response_error(:create_col, cs) |> Poison.encode!}
    end |> handle_response(conn)
  end

  post "/api/search" do
    params = conn.body_params |> Utils.atomize_map
    case %{}
    |> search(params, CollectionService, :collections)
    |> search(params, ConfigService, :configs)
    |> search(params, SchemaService, :schemas) do
      {:ok, result} ->
        {:ok, %{data: result} |> Poison.encode! }
      {:error, _} -> {:server_error, 0}
    end |> handle_response(conn)
  end

  get "/ping" do
    send_resp(conn, 200, "PONG")
  end

  match _ do
    send_resp(conn, 404, "Page not found")
  end

  defp search({:ok, result}, params, service, attr_name) do
    if params[:scope] && params[:scope] !=  Atom.to_string(attr_name) do
      {:ok, result}
    else
      search(result, params, service, attr_name)
    end
  end
  defp search({:error, message}, _, _, _) do
    {:error, message}
  end

  defp search(chain_result, params, service, attr_name) when is_map(chain_result) do
    if params[:scope] && params[:scope] != Atom.to_string(attr_name) do
      {:ok, chain_result}
    else
      case params |> service.search do
        result when is_list(result) ->
          {:ok, Map.put(chain_result, attr_name, result |> service.as_json) }
        {:error, message} -> {:error, message}
        _ -> {:ok, chain_result}
      end
    end
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

  defp response_error(:create_col, %Ecto.Changeset{} = cs) do
    %{success: false, errors: cs |> EctoError.mapper()}
  end

  defp response_error(:create_cog, :validate_schema, :schema_not_found) do
    %{success: false, errors: %{schema: "not found"}}
  end

  defp response_error(:create_cog, :validate_schema, errors) when is_list(errors) do
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