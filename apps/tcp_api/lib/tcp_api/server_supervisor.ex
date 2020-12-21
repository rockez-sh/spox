defmodule TcpApi.ServerSupervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: :tcp_server_supervisor)
  end

  def init(_) do
    children = [
      worker(TcpApi.Server, [])
    ]

    supervise(children, strategy: :one_for_one)
  end
end
