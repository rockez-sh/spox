defmodule Mix.Tasks.CoreSeed do
  use Mix.Task
  import Core.Utils

  def run(_) do
    :application.ensure_all_started(:core)

    {:ok, seeds} = YamlElixir.read_from_file(Path.join(__DIR__, "../../../priv/seed/seed.yaml"))

    seeds["schemas"]
    |> Enum.map(&atomize_map/1)
    |> Enum.each(fn x ->
      {:ok, _} = Core.SchemaService.create(x)
    end)

    seeds["collections"]
    |> Enum.map(&atomize_map/1)
    |> Enum.each(fn x ->
      {:ok, _} = Core.CollectionService.create(x)
    end)

    seeds["configs"]
    |> Enum.map(&atomize_map/1)
    |> Enum.each(fn x ->
      {:ok, _} = Core.ConfigService.create(x)

      case x |> Map.fetch(:collection) do
        {:ok, collection} ->
          {:ok, _} = Core.CollectionService.add_config(collection, [x[:name]], x[:namespace])

        :error ->
          {:ok}
      end
    end)
  end
end
