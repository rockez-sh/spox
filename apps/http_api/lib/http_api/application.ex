defmodule HttpApi.Application do
  import Core.Utils.Config
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # Starts a worker by calling: HttpApi.Worker.start_link(arg)
      # {HttpApi.Worker, arg}

      {Plug.Cowboy,
       scheme: :http, plug: HttpApi.Endpoints, options: [port: config(:http_api, :port)]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: HttpApi.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
