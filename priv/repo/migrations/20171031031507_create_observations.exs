defmodule Iclog.Repo.Migrations.CreateObservations do
  use Ecto.Migration

  def change do
    create table(:observations) do
      add :comment, :text
      add :observation_meta_id, references(:observation_metas, on_delete: :nothing)

      timestamps()
    end

    create index(:observations, [:observation_meta_id])
  end
end
