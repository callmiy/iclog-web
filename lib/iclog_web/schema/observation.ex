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
    field :inserted_at, :i_s_o_datetime
    field :updated_at, :i_s_o_datetime
  end

  object :paginated_obervation do
    field :entries, list_of(:observation)
    field :pagination, :pagination
  end

  object :observation_query do
    field :observation, type: :observation do
      arg :id, non_null(:id)

      resolve fn(%{id: id}, _info) ->
        case Observation.get(id) do
          nil  ->
            {:error, "Observation id #{id} not found"}

          obs ->
            {meta, obs_} = Map.pop obs, :observation_meta
            {:ok, Map.put(obs_, :meta, meta)}
        end
      end
    end
    field :observations, list_of(:observation) do

      resolve fn(_args, _info) ->
        obs = :with_meta
          |> Observation.list()
          |> observation_with_meta()
        {:ok, obs}
      end
    end

    field :paginated_observations, :paginated_obervation do
      arg :pagination, non_null(:pagination_params)

      resolve fn(args, _info) ->
        pagination_params = Map.get(args, :pagination, nil)
        %{entries: entries} = result = Observation.list(:with_meta, pagination_params)

        {
          :ok,
          Map.put(result, :entries, observation_with_meta(entries))
        }
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
    @desc "Update an observation"
    field :observation_mutation_update, type: :observation do
      arg :id, non_null(:id)
      arg :comment, :string
      arg :inserted_at, :string

      resolve fn(args, _) ->
        {id, params} = Map.pop(args, :id)

        case Observation.get(id) do
          nil ->
            message = "Observation does not exist!"
            {:error, message: message, id: message}

          observation ->
            with {:ok, data} <- Observation.update(observation, params, :with_meta) do
              {:ok, data}
            else
              {:error, changeset} ->
                {:error,  View.render(ChangesetView, "error.json", changeset: changeset)}
            end
        end
      end
    end
  end

  defp observation_with_meta(obs) do
    Stream.map(obs, fn(ob) ->
          {meta, new_ob} = Map.pop(ob, :observation_meta)
          Map.put(new_ob, :meta, meta)
        end)
      |> Enum.to_list()
  end
end
