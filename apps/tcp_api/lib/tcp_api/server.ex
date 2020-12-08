defmodule TcpApi.Server do
  import Core.Utils.Config
  require Logger

  def start_link do
    Logger.debug("[tcp] starting server on port :#{port()}")
    opts = [port: port()]
    {:ok, _} = :ranch.start_listener(:tcp, :ranch_tcp, %{num_acceptors: max_conn,socket_opts: opts} , TcpApi.Handler, [])
  end

  defp port do
    config(:tcp_api, :server, :port)
  end

  defp max_conn  do
    config(:tcp_api, :server, :max_conn)
  end
end