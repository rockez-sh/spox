defmodule Core.Redis do
  import Core.Utils.Config
  require Logger

  def start_link do
    [host: host, port: port] = config(:core, :redis)
    Redix.start_link(host: host, port: port, name: __MODULE__)
  end

  def command(command) do
    Logger.debug("Redis #{__MODULE__} #{inspect(command)}")
    Redix.command(__MODULE__, [command])
  end

  def command(command, args) when is_list(args) do
    Logger.debug("Redis #{__MODULE__} #{command} #{inspect(args)}")
    Redix.command(__MODULE__, [command | args])
  end

  def command(:get, key) do
    Logger.debug("Redis #{__MODULE__} :get #{key}")
    Redix.command(__MODULE__, ["GET", key])
  end

  def command(:set, key, value) do
    Logger.debug("Redis #{__MODULE__} :set #{key} #{value}")
    Redix.command(__MODULE__, ["SET", key, value])
  end

  def transaction_pipeline(commands) do
    Logger.debug("Redis #{__MODULE__} :transaction_pipeline #{inspect(commands)}")
    Redix.transaction_pipeline(__MODULE__, commands)
  end
end
