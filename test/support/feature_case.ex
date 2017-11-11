defmodule Iclog.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL

      alias Iclog.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Iclog.DataCase
      import Iclog.Factory

      import IclogWeb.Router.Helpers
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Iclog.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Iclog.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Iclog.Repo, self())
    {:ok, session} = Wallaby.start_session(metadata: metadata)
    {:ok, session: session}
  end
end