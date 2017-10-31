defmodule Iclog.ObservationMetas.ObservationMeta do
  use Ecto.Schema
  import Ecto.Changeset
  alias Iclog.ObservationMetas.ObservationMeta


  schema "observation_metas" do
    field :intro, :string
    field :title, :string

    timestamps()
  end

  @doc false
  def changeset(%ObservationMeta{} = observation_meta, attrs) do
    observation_meta
    |> cast(attrs, [:title, :intro])
    |> validate_required([:title, :intro])
  end
end
