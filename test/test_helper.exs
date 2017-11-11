ExUnit.configure(exclude: [integration: true])

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Iclog.Repo, :manual)

{:ok, _} = Application.ensure_all_started(:wallaby)
base_url_port = System.get_env("ICLOG_PHOENIX_PORT") || "4000"
Application.put_env(:wallaby, :base_url, "http://localhost:#{base_url_port}")
