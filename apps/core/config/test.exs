use Mix.Config

config :core, Core.Repo,
  adapter: Ecto.Adapters.MyXQL,
  database: "spock_db_test",
  username: "root",
  password: "sqlsecret",
  hostname: "0.0.0.0",
  port: 3306,
  pool: Ecto.Adapters.SQL.Sandbox

config :core, :redis,
  host: "0.0.0.0",
  port: 6379
