defmodule Iclog.ObservationMeta do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Iclog.Repo
  alias Iclog.ObservationMeta


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

  @doc """
  Returns the list of observation_metas.

  ## Examples

      iex> list_observation_metas()
      [%ObservationMeta{}, ...]

  """
  def list_observation_metas do
    Repo.all(ObservationMeta)
  end

  @doc """
  Gets a single observation_meta.

  Raises `Ecto.NoResultsError` if the Observation meta does not exist.

  ## Examples

      iex> get_observation_meta!(123)
      %ObservationMeta{}

      iex> get_observation_meta!(456)
      ** (Ecto.NoResultsError)

  """
  def get_observation_meta!(id), do: Repo.get!(ObservationMeta, id)

  @doc """
  Creates a observation_meta.

  ## Examples

      iex> create_observation_meta(%{field: value})
      {:ok, %ObservationMeta{}}

      iex> create_observation_meta(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_observation_meta(attrs \\ %{}) do
    %ObservationMeta{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a observation_meta.

  ## Examples

      iex> update_observation_meta(observation_meta, %{field: new_value})
      {:ok, %ObservationMeta{}}

      iex> update_observation_meta(observation_meta, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_observation_meta(%ObservationMeta{} = observation_meta, attrs) do
    observation_meta
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a ObservationMeta.

  ## Examples

      iex> delete_observation_meta(observation_meta)
      {:ok, %ObservationMeta{}}

      iex> delete_observation_meta(observation_meta)
      {:error, %Ecto.Changeset{}}

  """
  def delete_observation_meta(%ObservationMeta{} = observation_meta) do
    Repo.delete(observation_meta)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking observation_meta changes.

  ## Examples

      iex> change_observation_meta(observation_meta)
      %Ecto.Changeset{source: %ObservationMeta{}}

  """
  def change_observation_meta(%ObservationMeta{} = observation_meta) do
    changeset(observation_meta, %{})
  end
end
