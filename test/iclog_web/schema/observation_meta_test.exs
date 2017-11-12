defmodule IclogWeb.Schema.ObservationMetaTest do
  use Iclog.DataCase
  import Iclog.Observable.ObservationMeta.TestHelper

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta
  alias IclogWeb.Schema

  defp integers_to_strings(ints) do
    Enum.map ints, &Integer.to_string/1
  end

  describe "query" do
    test ":observation_metas" do
      %Observation{
        id: ob_id_,
        observation_meta: %ObservationMeta{id: meta_id_}
      } = insert(:observation)

      [ob_id, meta_id] = integers_to_strings [ob_id_, meta_id_]

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

  end
  test ":observation_metas_by_title_with_observations"  do
    %Observation{
      id: ob_id_,
      observation_meta: %ObservationMeta{id: meta_id_, title: title_}
    } = insert(:observation)
    [ob_id, meta_id] = integers_to_strings [ob_id_, meta_id_]
    title = title_ |> String.graphemes() |> Enum.take(3) |> Enum.join("")

    {query, query_params} = valid_query(:observation_metas_by_title_with_observations_query, title)

    assert {
        :ok,
        %{data:
            %{
                "observationMetasByTitle" => [
                  %{
                    "id" => ^meta_id,
                    "title" => ^title_,
                    "intro" => _,
                    "inserted_at" => _,
                    "updated_at" => _,
                    "observations" => [
                      %{
                        "id" => ^ob_id
                      }
                    ]
                  }
                ]
            }
        }
    } = Absinthe.run(query, Schema, variables: query_params)
  end
end
