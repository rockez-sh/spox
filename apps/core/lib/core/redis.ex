defmodule Core.Redis do
  import Core.Utils.Config

  def start_link do
    [host: host, port: port] = config(:core, :redis)
    Redix.start_link(host: host, port: port, name: __MODULE__)
  end

  def command(command, args) when is_list(args) do
    Redix.command(__MODULE__, [command | args])
  end

  def command(:get, key) do
    Redix.command(__MODULE__, ["GET", key])
  end

  def command(:set, key, value) do
    Redix.command(__MODULE__, ["SET", key, value])
  end
end
