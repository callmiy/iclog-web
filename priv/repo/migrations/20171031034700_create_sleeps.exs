defmodule Iclog.Repo.Migrations.CreateSleeps do
  use Ecto.Migration

  def change do
    create table(:sleeps) do
      add :start, :utc_datetime
      add :end, :utc_datetime
      add :comment, :text

      timestamps()
    end

  end
end
