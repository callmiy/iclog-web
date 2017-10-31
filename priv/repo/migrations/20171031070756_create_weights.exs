defmodule Iclog.Repo.Migrations.CreateWeights do
  use Ecto.Migration

  def change do
    create table(:weights) do
      add :weight, :float

      timestamps()
    end

  end
end
