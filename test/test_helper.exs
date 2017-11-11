ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Iclog.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, System.get_env("ICLOG_PHOENIX_PORT") || 4000  )
