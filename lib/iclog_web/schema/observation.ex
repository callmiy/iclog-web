defmodule IclogWeb.Schema.Observation do
  @moduledoc """
  Schema types
  """

  use Absinthe.Schema.Notation

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta
  alias IclogWeb.ChangesetView
  alias Phoenix.View

  @desc "An observation"
  object :observation do
    field :id, :id
    field :comment, :string
    field :meta, :observation_meta
    field :inserted_at, :timex_datetime
    field :updated_at, :timex_datetime
  end

  object :observation_query do
    field :observations, list_of(:observation) do
      resolve fn(_args, _info) ->
        obs = :with_meta
          |> Observation.list()
          |> Stream.map(fn(ob) ->
              {meta, new_ob} = Map.pop(ob, :observation_meta)
              Map.put(new_ob, :meta, meta)
            end)
          |> Enum.to_list()
        {:ok, obs}
      end
    end
  end

  input_object :meta do
    field :title, non_null(:string)
    field :intro, :string
  end

  @desc "Create an observation"
  object :Observation_mutations do

    @desc "Create an observation with its metadata simulatenously"
    field :observation_mutation_with_meta, type: :observation do
      arg :comment, non_null(:string)
      arg :meta, non_null(:meta)

      resolve fn(params, _) ->
        {m_params, o_params} = Map.pop( params, :meta)

        with {:ok, data} <- Observation.create(o_params, m_params) do
          {:ok, data} # {:ok, %{data: ..}}
        else
          {:error, changeset} ->
            {:ok,  View.render(ChangesetView, "error.json", changeset: changeset)} # {:ok, %{errors: ....}}
        end
      end

    end

    @desc "Create an observation with existing meta"
    field :observation_mutation, type: :observation do
      arg :comment, non_null(:string)
      arg :meta_id, non_null(:id)

      resolve fn(args, _) ->
        {meta_id, params_} = Map.pop(args, :meta_id)

        case ObservationMeta.get(meta_id) do
          nil ->
            message = "Meta does not exist!"
            #Absinthe will return:
            # {:ok, %{data: %{\"observationMutation\" => nil}, errors: %{message: message, meta: message} }
            {:error, message: message, meta: message}

          meta ->
            params = Map.put(params_, :observation_meta_id, meta_id)
            with {:ok, data} <- Observation.create(params) do
              {:ok, Map.put(data, :meta, meta)} # {:ok, %{data: ..}}
            else
              {:error, changeset} ->
                {:error,  View.render(ChangesetView, "error.json", changeset: changeset)} # {:ok, %{errors: ....}}
            end
        end

      end

    end
  end
end
