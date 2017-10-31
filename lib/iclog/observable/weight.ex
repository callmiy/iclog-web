defmodule Iclog.Observable.Weight do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Iclog.Repo
  alias Iclog.Observable.Weight


  schema "weights" do
    field :weight, :float

    timestamps()
  end

  @doc false
  def changeset(%Weight{} = weight, attrs) do
    weight
    |> cast(attrs, [:weight])
    |> validate_required([:weight])
  end

  @doc """
  Returns the list of weights.

  ## Examples

      iex> list()
      [%Weight{}, ...]

  """
  def list do
    Repo.all(Weight)
  end

  @doc """
  Gets a single weight.

  Raises `Ecto.NoResultsError` if the Weight does not exist.

  ## Examples

      iex> get!(123)
      %Weight{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Weight, id)

  @doc """
  Creates a weight.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Weight{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs \\ %{}) do
    %Weight{}
    |> Weight.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a weight.

  ## Examples

      iex> update(weight, %{field: new_value})
      {:ok, %Weight{}}

      iex> update(weight, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Weight{} = weight, attrs) do
    weight
    |> Weight.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Weight.

  ## Examples

      iex> delete(weight)
      {:ok, %Weight{}}

      iex> delete(weight)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Weight{} = weight) do
    Repo.delete(weight)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking weight changes.

  ## Examples

      iex> change(weight)
      %Ecto.Changeset{source: %Weight{}}

  """
  def change(%Weight{} = weight) do
    Weight.changeset(weight, %{})
  end
end
