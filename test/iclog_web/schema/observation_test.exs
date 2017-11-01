defmodule IclogWeb.Schema.ObservationTest do
  use Iclog.DataCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation
  alias IclogWeb.Schema

  describe "query" do
    test ":observation_query" do
      %Observation{id: id} = fixture()

      assert{:ok, %{data: %{"observations" => [%{"id" => ^id}]}}} =
        Absinthe.run(valid_query(:observation_query), Schema)
    end
  end

  describe "mutation" do
    test ":Observation_mutation_with_meta succeeds" do
      assert {:ok, %{data: %{"observationWithMeta" => %{"id" => _} } }} =
        Absinthe.run(valid_query(:Observation_mutation_with_meta), Schema)
    end

    test ":Observation_mutation_with_meta errors" do
      assert {:ok, %{errors: _}} =
        Absinthe.run(invalid_query(:Observation_mutation_with_meta), Schema)
    end
  end
  
end
