defmodule IclogWeb.Schema.ObservationTest do
  use Iclog.DataCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObmHelper
  alias IclogWeb.Schema

  describe "query" do
    test "observation_query returns ok" do
      %Observation{
        id: id_,
        comment: comment,
        observation_meta: %ObservationMeta{
          id: obm_id_,
          title: title,
          intro: intro,
        }
      } = insert(:observation)

      id = Integer.to_string id_
      obm_id = Integer.to_string obm_id_

      {query, params} = valid_query(:observation, id)

      assert {:ok, %{
          data: %{
            "observation" => %{
              "id" => ^id,
              "comment" => ^comment,
              "insertedAt" => _,
              "updatedAt" => _,
              "meta" => %{
                "id" => ^obm_id,
                "title" => ^title,
                "intro" => ^intro,
              }
            }
          }
        }
      } = Absinthe.run(query, Schema, variables: params)
    end

    test "observation_query returns error" do
      {query, params} = valid_query(:observation, "0")

      assert {:ok, %{
          errors: [%{message: _}]
        }
      } = Absinthe.run(query, Schema, variables: params)
    end

    test "observations_query" do
      %Observation{
        id: id_,
        comment: comment,
        observation_meta: %ObservationMeta{
          id: obm_id_,
          title: title,
          intro: intro,
        }
      } = insert(:observation)

      id = Integer.to_string id_
      obm_id = Integer.to_string obm_id_

      assert {:ok, %{
          data: %{
            "observations" => [%{
              "id" => ^id,
              "comment" => ^comment,
              "insertedAt" => _,
              "updatedAt" => _,
              "meta" => %{
                "id" => ^obm_id,
                "title" => ^title,
                "intro" => ^intro,
              }
            }]
          }
        }
      } = Absinthe.run(valid_query(:observations), Schema)
    end

    test ":paginated_observations_query page number 1 succeeds" do
      insert_list(11, :observation)

      {query, params} = valid_query(:paginated_observations, 1)

      {:ok, %{
          data: %{
            "paginatedObservations" => %{
              "entries" => obs,
              "pagination" => %{
                "totalEntries" => 11,
                "pageNumber" => 1,
                "pageSize" => 10,
                "totalPages" => 2,
              }
            }
          }
        }
      } = Absinthe.run(query, Schema, variables: params)

      assert length(obs) == 10

      assert %{
        "id" => _,
        "comment" => _,
        "insertedAt" => _,
        "updatedAt" => _,
        "meta" => %{
          "id" => _,
          "title" => _,
          "intro" => _,
        }
      } = List.first(obs)
    end

    test ":paginated_observations_query page number 2 succeeds" do
      insert_list(11, :observation)

      {query, params} = valid_query(:paginated_observations, 2)

      {:ok, %{
          data: %{
            "paginatedObservations" => %{
              "entries" => obs,
              "pagination" => %{
                "totalEntries" => 11,
                "pageNumber" => 2,
                "pageSize" => 10,
                "totalPages" => 2,
              }
            }
          }
        }
      } = Absinthe.run(query, Schema, variables: params)

      assert [%{
        "id" => _,
        "comment" => _,
        "insertedAt" => _,
        "updatedAt" => _,
        "meta" => %{
          "id" => _,
          "title" => _,
          "intro" => _,
        }
      }] = obs
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

    test ":observation_mutation_update succeeds" do
      %Observation{
        id: id_,
        comment: comment_,
        inserted_at: inserted_at_,
        observation_meta: %ObservationMeta{id: obm_id_}
      } = insert(:observation)

      id = Integer.to_string id_
      obm_id = Integer.to_string obm_id_
      comment = "#{comment_}-updated"

      inserted_at = inserted_at_
      |> Timex.shift(minutes: 5)
      |> Timex.format!("{ISO:Extended:Z}")

      query = valid_query :observation_mutation_update


      params = %{
        "id" => id,
        "comment" => comment,
        "insertedAt" => inserted_at,
      }

      assert {:ok,
            %{data:
              %{"observationMutationUpdate" =>
                %{
                    "id" =>^id,
                    "comment" => ^comment,
                    "insertedAt" => ^inserted_at,
                    "updatedAt" => _,
                    "meta" => %{
                      "id" => ^obm_id
                    }
                }
              }
            }
        } =
      Absinthe.run(query, Schema, variables: params)
    end

    test ":observation_mutation_update errors" do
      query = valid_query :observation_mutation_update

      params = %{
        "id" => "0",
        "comment" => "",
        "insertedAt" => "",
      }

      assert {:ok, %{errors: _}} =
        Absinthe.run(query, Schema, variables: params)
    end
  end
end
