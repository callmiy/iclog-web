defmodule Iclog.Observable.Observation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  
  alias Iclog.Repo
  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta


  schema "observations" do
    field :comment, :string
    belongs_to :observation_meta, ObservationMeta

    timestamps()
  end

  @doc false
  def changeset(%Observation{} = observation, attrs) do
    observation
    |> cast(attrs, [:observation_meta_id, :comment])
    |> validate_required([:observation_meta_id, :comment])
  end

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list()
      [%Observation{}, ...]

      iex> list(:with_meta)

  """
  def list(:with_meta) do
    Repo.all from observation in Observation,
      join: meta in assoc(observation, :observation_meta),
      preload: [observation_meta: meta]
  end
  def list do
    Repo.all(Observation)
  end

  @doc """
  Gets a single observation.

  Raises `Ecto.NoResultsError` if the Observation does not exist.

  ## Examples

      iex> get!(123)
      %Observation{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Observation, id)

  @doc """
  Creates a observation.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Observation{}}

      iex> create(%{comment: value}, meta)
      {:ok, %Observation{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs, meta) do
    with {:ok, %ObservationMeta{} = m} <- ObservationMeta.create(meta),
          {:ok, %Observation{} = o} <- create(merge_observation_with_meta(attrs, m.id) ) do
      {:ok, Map.put(o, :meta, m)}      
    end
  end
  def create(attrs \\ %{}) do
    %Observation{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  defp merge_observation_with_meta(%{comment: _} = observation, id) do
    Map.put(observation, :observation_meta_id, id)
  end
  defp merge_observation_with_meta(%{"comment" => _} = observation, id) do
    Map.put(observation, "observation_meta_id", id)
  end
  defp merge_observation_with_meta(_, id) do
    %{observation_meta_id: id}
  end

  @doc """
  Updates a observation.

  ## Examples

      iex> update(observation, %{field: new_value})
      {:ok, %Observation{}}

      iex> update(observation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Observation{} = observation, attrs) do
    observation
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Observation.

  ## Examples

      iex> delete(observation)
      {:ok, %Observation{}}

      iex> delete(observation)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Observation{} = observation) do
    Repo.delete(observation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking observation changes.

  ## Examples

      iex> change(observation)
      %Ecto.Changeset{source: %Observation{}}

  """
  def change(%Observation{} = observation) do
    changeset(observation, %{})
  end
end
