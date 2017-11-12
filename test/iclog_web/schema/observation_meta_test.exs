defmodule IclogWeb.Schema.ObservationMetaTest do
  use Iclog.DataCase
  import Iclog.Observable.ObservationMeta.TestHelper

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta
  alias IclogWeb.Schema

  defp make_observation_with_meta(_) do
    %Observation{
      id: ob_id_,
      observation_meta: %ObservationMeta{id: meta_id_}
    } = insert(:observation)

    ob_id = Integer.to_string ob_id_
    meta_id = Integer.to_string meta_id_
    {:ok, ob_id: ob_id, meta_id: meta_id}
  end

  describe "query" do
    setup [:make_observation_with_meta]

    test ":observation_metas", %{meta_id: meta_id, ob_id: ob_id} do
      assert {
          :ok,
          %{data:
              %{
                  "observationMetas" => [
                    %{
                      "id" => ^meta_id,
                      "title" => _,
                      "intro" => _,
                      "inserted_at" => _,
                      "updated_at" => _,
                      "observations" => [
                        %{"id" => ^ob_id}
                      ]
                    }
                  ]
              }
          }
      } = Absinthe.run(valid_query(:observation_metas_query), Schema)
    end

    test ":observation_metas_by_title", %{meta_id: meta_id}  do
      {query, query_params} = valid_query(:observation_metas_by_title_query, "som")

      assert {
          :ok,
          %{data:
              %{
                  "observationMetasByTitle" => [
                    %{
                      "id" => ^meta_id,
                      "title" => _,
                      "intro" => _,
                      "inserted_at" => _,
                      "updated_at" => _,
                    }
                  ]
              }
          }
      } = Absinthe.run(query, Schema, variables: query_params)
    end
  end
end
