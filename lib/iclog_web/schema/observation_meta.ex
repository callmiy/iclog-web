defmodule IclogWeb.Schema.ObservationMeta do
  @moduledoc """
  Schema types
  """

  use Absinthe.Schema.Notation
  alias Iclog.Observable.ObservationMeta

  @desc "An observation metadata"
  object :observation_meta do
    field :id, :id
    field :intro, :string
    field :title, :string
    field :observations, list_of(:observation)
    field :inserted_at, :timex_datetime
    field :updated_at, :timex_datetime
  end

  object :observation_meta_query do
    field :observation_metas, list_of(:observation_meta) do
      resolve fn(_args, _info) ->
        {:ok, ObservationMeta.list(:with_observations)}
      end
    end

    field :observation_metas_by_title, list_of(:observation_meta) do
      arg :title, non_null(:string)

      resolve fn(args, _info) ->
        {:ok, ObservationMeta.list(:by_title, Map.get(args, :title))}
      end
    end
  end
end
