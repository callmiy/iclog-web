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
    field :inserted_at, :i_s_o_datetime
    field :updated_at, :i_s_o_datetime
  end

  object :observation_meta_query do
    field :observation_metas, list_of(:observation_meta) do
      resolve fn(_args, _info) ->
        {:ok, ObservationMeta.list(:with_observations)}
      end
    end

    field :observation_metas_by_title, list_of(:observation_meta) do
      arg :title, non_null(:string)
      arg :with_observations, :boolean

      resolve fn(args, _info) ->
        {with_observations, params} = Map.pop(args, :with_observations)

        metas = if with_observations do
          ObservationMeta.list(
            :by_title,
            :with_observations,
            Map.get(params, :title)
          )
        else
          ObservationMeta.list(:by_title, Map.get(params, :title))
        end
        {:ok, metas}
      end
    end
  end
end
