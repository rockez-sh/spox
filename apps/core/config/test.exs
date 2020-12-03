use Mix.Config

config :core, Core.Repo,
  adapter: Ecto.Adapters.MyXQL,
  database: "spock_db_test",
  username: "root",
  password: "sqlsecret",
  hostname: "localhost",
  port: 3306,
  pool: Ecto.Adapters.SQL.Sandbox