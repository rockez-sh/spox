# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# third-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :core, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:core, :key)
#
# You can also configure a third-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"
config :core, ecto_repos: [Core.Repo]

config :core, Core.Repo,
  adapter: Ecto.Adapters.MyXQL,
  database: "spock_db",
  username: "root",
  password: "sqlsecret",
  hostname: "localhost",
  port: 3306

config :core,
  config_transformer: Core.Utils.Config.Transformer

import_config "#{Mix.env()}.exs"
