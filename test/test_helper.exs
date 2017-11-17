Application.ensure_all_started(:hound)
ExUnit.start exclude: [integration: true]
Ecto.Adapters.SQL.Sandbox.mode(Iclog.Repo, :manual)
Absinthe.Test.prime(IclogWeb.Schema)
