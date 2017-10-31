defmodule Iclog.Repo.Migrations.WeightsWeightNotNullable do
  use Ecto.Migration

  def change do
    alter table("weights") do
      modify :weight, :float, null: false
    end
  end
end
