defmodule Iclog.Repo.Migrations.CreateMeals do
  use Ecto.Migration

  def change do
    create table(:meals) do
      add :meal, :text, null: false
      add :time, :utc_datetime, null: false
      add :comment, :text, null: true

      timestamps()
    end

  end
end
