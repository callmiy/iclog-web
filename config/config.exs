# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :iclog,
  ecto_repos: [Iclog.Repo]

# Configures the endpoint
config :iclog, IclogWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "LLzkQit+WUt5ybBS094SUOEy8XSPfZE27FO6ulS7D9NW3haZw41SNGwMqnLxvG8R",
  render_errors: [view: IclogWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Iclog.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :absinthe,
  schema: IclogWeb.Schema

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
