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

  """
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

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs \\ %{}) do
    %Observation{}
    |> changeset(attrs)
    |> Repo.insert()
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
