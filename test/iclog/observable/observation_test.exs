defmodule Iclog.Observable.ObservationTest do
  use Iclog.DataCase

  alias Iclog.Observable.Observation

    @valid_attrs %{comment: "some comment"}
    @update_attrs %{comment: "some updated comment"}
    @invalid_attrs %{comment: nil}

    def observation_fixture(attrs \\ %{}) do
      {:ok, observation} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Observation.create_observation()

      observation
    end

    test "list_observations/0 returns all observations" do
      observation = observation_fixture()
      assert Observation.list_observations() == [observation]
    end

    test "get_observation!/1 returns the observation with given id" do
      observation = observation_fixture()
      assert Observation.get_observation!(observation.id) == observation
    end

    test "create_observation/1 with valid data creates a observation" do
      assert {:ok, %Observation{} = observation} = Observation.create_observation(@valid_attrs)
      assert observation.comment == "some comment"
    end

    test "create_observation/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Observation.create_observation(@invalid_attrs)
    end

    test "update_observation/2 with valid data updates the observation" do
      observation = observation_fixture()
      assert {:ok, observation} = Observation.update_observation(observation, @update_attrs)
      assert %Observation{} = observation
      assert observation.comment == "some updated comment"
    end

    test "update_observation/2 with invalid data returns error changeset" do
      observation = observation_fixture()
      assert {:error, %Ecto.Changeset{}} = Observation.update_observation(observation, @invalid_attrs)
      assert observation == Observation.get_observation!(observation.id)
    end

    test "delete_observation/1 deletes the observation" do
      observation = observation_fixture()
      assert {:ok, %Observation{}} = Observation.delete_observation(observation)
      assert_raise Ecto.NoResultsError, fn -> Observation.get_observation!(observation.id) end
    end

    test "change_observation/1 returns a observation changeset" do
      observation = observation_fixture()
      assert %Ecto.Changeset{} = Observation.change_observation(observation)
    end
  
end
