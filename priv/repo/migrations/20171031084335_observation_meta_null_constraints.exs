defmodule Iclog.Repo.Migrations.ObservationMetaNullConstraints do
  use Ecto.Migration

  def change do
    alter table(:observation_metas) do
      modify :title, :string, null: false
      modify :intro, :text, null: true
    end
  end
end
