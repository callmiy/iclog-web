defmodule Iclog.Observation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false
  
  alias Iclog.Repo
  alias Iclog.Observation
  alias Iclog.ObservationMeta


  schema "observations" do
    field :comment, :string
    belongs_to :observation_meta, ObservationMeta

    timestamps()
  end

  @doc false
  def changeset(%Observation{} = observation, attrs) do
    observation
    |> cast(attrs, [:comment])
    |> validate_required([:comment])
  end

  @doc """
  Returns the list of observations.

  ## Examples

      iex> list_observations()
      [%Observation{}, ...]

  """
  def list_observations do
    Repo.all(Observation)
  end

  @doc """
  Gets a single observation.

  Raises `Ecto.NoResultsError` if the Observation does not exist.

  ## Examples

      iex> get_observation!(123)
      %Observation{}

      iex> get_observation!(456)
      ** (Ecto.NoResultsError)

  """
  def get_observation!(id), do: Repo.get!(Observation, id)

  @doc """
  Creates a observation.

  ## Examples

      iex> create_observation(%{field: value})
      {:ok, %Observation{}}

      iex> create_observation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_observation(attrs \\ %{}) do
    %Observation{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a observation.

  ## Examples

      iex> update_observation(observation, %{field: new_value})
      {:ok, %Observation{}}

      iex> update_observation(observation, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_observation(%Observation{} = observation, attrs) do
    observation
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Observation.

  ## Examples

      iex> delete_observation(observation)
      {:ok, %Observation{}}

      iex> delete_observation(observation)
      {:error, %Ecto.Changeset{}}

  """
  def delete_observation(%Observation{} = observation) do
    Repo.delete(observation)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking observation changes.

  ## Examples

      iex> change_observation(observation)
      %Ecto.Changeset{source: %Observation{}}

  """
  def change_observation(%Observation{} = observation) do
    changeset(observation, %{})
  end
end
