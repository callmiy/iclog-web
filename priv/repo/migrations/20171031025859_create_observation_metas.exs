defmodule Iclog.Repo.Migrations.CreateObservationMetas do
  use Ecto.Migration

  def change do
    create table(:observation_metas) do
      add :title, :string
      add :intro, :text

      timestamps()
    end

  end
end
