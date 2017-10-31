defmodule Iclog.ObservationMetasTest do
  use Iclog.DataCase

  alias Iclog.ObservationMetas

  describe "observation_metas" do
    alias Iclog.ObservationMetas.ObservationMeta

    @valid_attrs %{intro: "some intro", title: "some title"}
    @update_attrs %{intro: "some updated intro", title: "some updated title"}
    @invalid_attrs %{intro: nil, title: nil}

    def observation_meta_fixture(attrs \\ %{}) do
      {:ok, observation_meta} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ObservationMetas.create_observation_meta()

      observation_meta
    end

    test "list_observation_metas/0 returns all observation_metas" do
      observation_meta = observation_meta_fixture()
      assert ObservationMetas.list_observation_metas() == [observation_meta]
    end

    test "get_observation_meta!/1 returns the observation_meta with given id" do
      observation_meta = observation_meta_fixture()
      assert ObservationMetas.get_observation_meta!(observation_meta.id) == observation_meta
    end

    test "create_observation_meta/1 with valid data creates a observation_meta" do
      assert {:ok, %ObservationMeta{} = observation_meta} = ObservationMetas.create_observation_meta(@valid_attrs)
      assert observation_meta.intro == "some intro"
      assert observation_meta.title == "some title"
    end

    test "create_observation_meta/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ObservationMetas.create_observation_meta(@invalid_attrs)
    end

    test "update_observation_meta/2 with valid data updates the observation_meta" do
      observation_meta = observation_meta_fixture()
      assert {:ok, observation_meta} = ObservationMetas.update_observation_meta(observation_meta, @update_attrs)
      assert %ObservationMeta{} = observation_meta
      assert observation_meta.intro == "some updated intro"
      assert observation_meta.title == "some updated title"
    end

    test "update_observation_meta/2 with invalid data returns error changeset" do
      observation_meta = observation_meta_fixture()
      assert {:error, %Ecto.Changeset{}} = ObservationMetas.update_observation_meta(observation_meta, @invalid_attrs)
      assert observation_meta == ObservationMetas.get_observation_meta!(observation_meta.id)
    end

    test "delete_observation_meta/1 deletes the observation_meta" do
      observation_meta = observation_meta_fixture()
      assert {:ok, %ObservationMeta{}} = ObservationMetas.delete_observation_meta(observation_meta)
      assert_raise Ecto.NoResultsError, fn -> ObservationMetas.get_observation_meta!(observation_meta.id) end
    end

    test "change_observation_meta/1 returns a observation_meta changeset" do
      observation_meta = observation_meta_fixture()
      assert %Ecto.Changeset{} = ObservationMetas.change_observation_meta(observation_meta)
    end
  end
end
