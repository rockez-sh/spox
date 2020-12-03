:application.ensure_all_started(:core)
ExUnit.start(capture_log: true)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Core.Repo, :manual)
