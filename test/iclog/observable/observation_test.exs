defmodule Iclog.Observable.ObservationTest do
  use Iclog.DataCase

  alias Iclog.Observable.Observation

    @valid_attrs %{comment: "some comment"}
    @update_attrs %{comment: "some updated comment"}
    @invalid_attrs %{comment: nil}

    def fixture(attrs \\ %{}) do
      {:ok, observation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Observation.create()

      observation
    end

    test "list/0 returns all observations" do
      observation = fixture()
      assert Observation.list() == [observation]
    end

    test "get!/1 returns the observation with given id" do
      observation = fixture()
      assert Observation.get!(observation.id) == observation
    end

    test "create/1 with valid data creates a observation" do
      assert {:ok, %Observation{} = observation} = Observation.create(@valid_attrs)
      assert observation.comment == "some comment"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Observation.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the observation" do
      observation = fixture()
      assert {:ok, observation} = Observation.update(observation, @update_attrs)
      assert %Observation{} = observation
      assert observation.comment == "some updated comment"
    end

    test "update/2 with invalid data returns error changeset" do
      observation = fixture()
      assert {:error, %Ecto.Changeset{}} = Observation.update(observation, @invalid_attrs)
      assert observation == Observation.get!(observation.id)
    end

    test "delete/1 deletes the observation" do
      observation = fixture()
      assert {:ok, %Observation{}} = Observation.delete(observation)
      assert_raise Ecto.NoResultsError, fn -> Observation.get!(observation.id) end
    end

    test "change/1 returns a observation changeset" do
      observation = fixture()
      assert %Ecto.Changeset{} = Observation.change(observation)
    end
  
end
