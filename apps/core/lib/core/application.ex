defmodule Core.Application do
  use Application
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    children = [
      worker(Core.Repo, [])
    ]
    Supervisor.start_link(children, [strategy: :one_for_one, name: Core.Supervisor])
  end
end

