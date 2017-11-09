defmodule IclogWeb.Schema.ObservationTest do
  use Iclog.DataCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObmHelper
  alias IclogWeb.Schema

  describe "query" do
    test ":observation_query" do
      %Observation{id: id_} = fixture()
      id = Integer.to_string id_

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

    test ":Observation_mutation succeeds" do
      %ObservationMeta{id: id} = ObmHelper.fixture()
      obm_id = Integer.to_string id
      {query, params} = valid_query(:Observation_mutation, id)

      assert {:ok,
                %{data:
                  %{"observationMutation" =>
                    %{
                        "id" => _,
                        "meta" => %{
                          "id" => ^obm_id
                        }
                    }
                  }
                }
            } =
        Absinthe.run(query, Schema, variables: params)
    end

    test ":Observation_mutation errors" do
      {query, params} = valid_query(:Observation_mutation, 0)

      assert {:ok, %{errors: _}} =
        Absinthe.run(query, Schema, variables: params)
    end
  end
end
