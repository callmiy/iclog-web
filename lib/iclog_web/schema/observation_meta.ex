defmodule IclogWeb.Schema.ObservationMeta do
  @moduledoc """
  Schema types
  """

  use Absinthe.Schema.Notation

  @desc "An observation metadata"
  object :observation_meta do
    field :id, :id
    field :intro, :string
    field :title, :string
    field :observations, list_of(:observation)
    field :inserted_at, :timex_datetime
    field :updated_at, :timex_datetime
  end  
end
