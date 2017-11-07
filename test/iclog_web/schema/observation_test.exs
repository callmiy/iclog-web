defmodule IclogWeb.Schema.ObservationTest do
  use Iclog.DataCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation
  alias IclogWeb.Schema

  describe "query" do
    test ":observation_query" do
      %Observation{id: id} = fixture()

      assert {
          :ok,
          %{data:
              %{
                  "observations" => [
                    %{
                      "id" => ^id,
                      "comment" => _,
                      "insertedAt" => _,
                      "updatedAt" => _,
                      "meta" => %{
                        "id" => _,
                        "title" => _,
                        "intro" => _
                      }
                    }
                  ]
              }
          }
      } = Absinthe.run(valid_query(:observation_query), Schema)
        
    end
  end

  describe "mutation" do
    test ":Observation_mutation_with_meta succeeds" do
      {query, params} = valid_query(:Observation_mutation_with_meta)

      assert {:ok, %{data: %{"observationMutationWithMeta" => %{"id" => _} } }} =
        Absinthe.run(query, Schema, variables: params)
    end

    test ":Observation_mutation_with_meta errors" do
      {query, params} = invalid_query(:Observation_mutation_with_meta)

      assert {:ok, %{errors: _}} =
        Absinthe.run(query, Schema, variables: params)
    end
  end
  
end
