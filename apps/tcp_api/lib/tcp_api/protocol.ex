defmodule TcpApi.Protocol do
  require Logger
  require Poison
  alias Core.ConfigService, as: ConfigSVC
  alias Core.CollectionService
  def process("val:cog:" <> keypair ) do
    [namespace, name] = String.split(keypair, ".")
    case ConfigSVC.get_value(name, namespace) do
      {:ok, nil} -> "can't find cog value for #{namespace}.#{name}" |> reply(:not_found)
      {:ok, data} -> reply(data)
    end
  end

  def process("ver:cog:" <> keypair ) do
    [namespace, name] = String.split(keypair, ".")
    case ConfigSVC.get_version(name, namespace) do
      {:ok, nil} -> "can't find cog version for #{namespace}.#{name}" |> reply(:not_found)
      {:ok, data} -> reply(data)
    end
  end

  def process("ver:col:" <> keypair ) do
    [namespace, name] = String.split(keypair, ".")
    case CollectionService.get_version(name, namespace) do
      {:ok, nil} -> "can't find col version for #{namespace}.#{name}" |> reply(:not_found)
      {:ok, data} -> reply(data)
    end
  end

  def process("exit"), do: :exit

  def process(_), do: :error

  defp reply(data), do: {:reply, "0 #{data}"}
  defp reply(data, :not_found), do: {:reply, data |> error_not_found}

  defp error_not_found(msg), do: "1 ERR:NOT_FOUND (#{msg})"
end