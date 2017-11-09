defmodule IclogWeb.Schema.ObservationMetaTest do
  use Iclog.DataCase
  import Iclog.Observable.ObservationMeta.TestHelper

  alias Iclog.Observable.Observation
  alias IclogWeb.Schema
  alias Iclog.Observable.Observation.TestHelper, as: ObHelper

  describe "query" do
    setup [:init]

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

    test ":observation_metas_by_title", %{meta_id: meta_id, ob_id: ob_id}  do
      {query, query_params} = valid_query(:observation_metas_by_title_query)

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
                      "observations" => [
                        %{"id" => ^ob_id}
                      ]
                    }
                  ]
              }
          }
      } = Absinthe.run(query, Schema, variables: query_params)
    end
  end

  defp init(%{describe: "query"}) do
    %{observation_meta_id: meta_id_} = ob_parms = ObHelper.valid_attrs(:with_meta)
    meta_id = Integer.to_string meta_id_

    %Observation{id: ob_id_} = ObHelper.fixture(ob_parms)
    ob_id = Integer.to_string ob_id_

    {:ok, meta_id: meta_id, ob_id: ob_id}
  end
end
