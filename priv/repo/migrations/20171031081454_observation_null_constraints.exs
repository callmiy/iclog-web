defmodule Iclog.Repo.Migrations.ObservationNullConstraints do
  use Ecto.Migration

  def change do
    execute "ALTER TABLE observations DROP CONSTRAINT observations_observation_meta_id_fkey"

    alter table("observations") do
      modify :comment, :text, null: false
      modify :observation_meta_id, references(:observation_metas, on_delete: :nothing), null: false
      
    end
  end
end
