defmodule Iclog.Repo.Migrations.SleepFieldsNullConstraints do
  use Ecto.Migration

  def change do
    alter table("sleeps") do
      modify :start, :utc_datetime, null: false
      modify :end, :utc_datetime, null: false
      modify :comment, :text, null: true
    end
  end
end
