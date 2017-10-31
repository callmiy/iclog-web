defmodule Iclog.Observable.Sleep do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Iclog.Repo
  alias Iclog.Observable.Sleep

  @timestamps_opts [type: Timex.Ecto.DateTime,
                      autogenerate: {Timex.Ecto.DateTime, :autogenerate, []}]

  schema "sleeps" do
    field :comment, :string
    field :end, :utc_datetime
    field :start, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%Sleep{} = sleep, attrs) do
    sleep
    |> cast(attrs, [:start, :end, :comment])
    |> validate_required([:start, :end, :comment])
  end

  @doc """
  Returns the list of sleeps.

  ## Examples

      iex> list()
      [%Sleep{}, ...]

  """
  def list do
    Repo.all(Sleep)
  end

  @doc """
  Gets a single sleep.

  Raises `Ecto.NoResultsError` if the Sleep does not exist.

  ## Examples

      iex> get!(123)
      %Sleep{}

      iex> get!(456)
      ** (Ecto.NoResultsError)

  """
  def get!(id), do: Repo.get!(Sleep, id)

  @doc """
  Creates a sleep.

  ## Examples

      iex> create(%{field: value})
      {:ok, %Sleep{}}

      iex> create(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create(attrs \\ %{}) do
    %Sleep{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a sleep.

  ## Examples

      iex> update(sleep, %{field: new_value})
      {:ok, %Sleep{}}

      iex> update(sleep, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update(%Sleep{} = sleep, attrs) do
    sleep
    |> changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Sleep.

  ## Examples

      iex> delete(sleep)
      {:ok, %Sleep{}}

      iex> delete(sleep)
      {:error, %Ecto.Changeset{}}

  """
  def delete(%Sleep{} = sleep) do
    Repo.delete(sleep)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking sleep changes.

  ## Examples

      iex> change(sleep)
      %Ecto.Changeset{source: %Sleep{}}

  """
  def change(%Sleep{} = sleep) do
    changeset(sleep, %{})
  end
end
