defmodule Iclog.Observable.ObservationTest do
  use Iclog.DataCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObservationMetaHelper
  alias Iclog.Observable.ObservationMeta
  alias Iclog.Schema

  describe "observation" do
    test "list/0 returns all observations" do
      observation = fixture()
      assert Observation.list() == [observation]
    end

    test "list/1 returns all observations with meta preloaded" do
      %ObservationMeta{id: meta_id} = ObservationMetaHelper.fixture
      %Observation{id: id} = valid_attrs(:no_meta)
        |> Map.put_new(:observation_meta_id, meta_id)
        |> fixture()

      assert [ %Observation{
          id: ^id,
          observation_meta: %ObservationMeta{id: ^meta_id}  
      } ] = Observation.list(:with_meta)
    end

    test "get!/1 returns the observation with given id" do
      observation = fixture()
      assert Observation.get!(observation.id) == observation
    end

    test "create/1 with valid data creates a observation" do
       assert {:ok, %Observation{} = observation} = Observation.create(valid_attrs())
      assert observation.comment == "some comment"
    end

    test "create/2 with valid data creates a observation" do
      assert {:ok, %{id: _, meta: %{id: _}}} = valid_attrs(:no_meta)
        |> Observation.create(ObservationMetaHelper.valid_attrs())
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Observation.create(invalid_attrs())
    end

    test "update/2 with valid data updates the observation" do
      observation = fixture()
      assert {:ok, observation} = Observation.update(observation, update_attrs())
      assert %Observation{} = observation
      assert observation.comment == "some updated comment"
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

  describe "observation schema" do
    test ":observation_query" do
      %Observation{id: id} = fixture()

      assert{:ok, %{data: %{"observations" => [%{"id" => _}]}}} =
        """
        {
          observations {
            id
          }
        }
        """
          |> Absinthe.run(Schema)
    end

    test ":Observation_mutation_with_meta" do
      assert {:ok, %{data: %{"observationWithMeta" => %{"id" => _} } }} =
        """
        mutation createObservationAndMeta {
          observationWithMeta(
            comment: "some comment",
            meta: {title: "nice title"}
          ) {
            id
          }
        }
        """
          |> Absinthe.run(Schema)
    end
  end
  
end
