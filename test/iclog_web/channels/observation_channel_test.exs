defmodule IclogWeb.ObservationChannelTest do
  use IclogWeb.ChannelCase

  import Iclog.Observable.Observation.TestHelper

  alias IclogWeb.ObservationChannel
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObmHelper
  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta

  setup do
    {query, params} = valid_query(:paginated_observations, 1)

    {:ok, response, socket} =
    socket("user_id", %{some: :assign})
    |> subscribe_and_join(
        ObservationChannel,
        "observation:observation",
        %{"query" => query, "params" => params}
      )

    {:ok, socket: socket, socket_response: response}
  end

  describe "new_observation" do
    test "with_meta replies with status ok, observation and meta", %{socket: socket} do
      {query, params} = valid_query(:Observation_mutation_with_meta)

      ref = push socket, "new_observation", %{
        "with_meta" => "yes",
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{data:  %{"observationMutationWithMeta" => %{"id" => _, "meta" => _}}},
        1000
      )
    end

    test "with_meta replies with status error", %{socket: socket} do
      {query, params} = invalid_query(:Observation_mutation_with_meta)

      ref = push socket, "new_observation", %{
        "with_meta" => "yes",
        "query" => query,
        "params" => params
      }

      assert_reply ref, :error, %{errors:  _}, 1000
    end

    test "replies with status ok, observation and meta", %{socket: socket} do
      meta = ObmHelper.fixture()
      {query, params} = valid_query(:Observation_mutation, meta.id)

      ref = push socket, "new_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{data:  %{"observationMutation" => %{"id" => _, "meta" => _}}},
        1000
      )
    end

    test "replies with status error", %{socket: socket} do
      {query, params} = valid_query(:Observation_mutation, 0)

      ref = push socket, "new_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply ref, :error, %{errors:  _}, 1000
    end
  end

  describe "search_metas_by_title" do
    test "replies with status ok and  metas", %{socket: socket} do
      insert(:observation_meta)

      {query, params} = ObmHelper.valid_query(:observation_metas_by_title_query, "som")

      ref = push socket, "search_metas_by_title", %{
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{data:  %{"observationMetasByTitle" => [%{"id" => _, "title" => _}]}},
        1000
      )
    end
  end

  describe "list_observations" do
    test "replies with status ok and list of observations", %{socket: socket} do
      insert_list(11, :observation)

      {query, params} = valid_query(:paginated_observations, 1)

      ref = push socket, "list_observations", %{
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{
          data: %{
            "paginatedObservations" => %{
              "entries" => _,
              "pagination" => %{
                "totalEntries" => 11,
                "pageNumber" => 1,
                "pageSize" => 10,
                "totalPages" => 2,
              }
            }
          }
        },
        1000
      )
    end
  end

  describe "get_observation" do
    test "replies with status ok and observation", %{socket: socket} do
      obs = insert(:observation)
      id = Integer.to_string obs.id

      {query, params} = valid_query(:observation, id)

      ref = push socket, "get_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{
          data: %{
            "observation" => %{
              "id" => ^id,
              "meta" => %{
                "id" => _
              }
            }
          }
        },
        1000
      )
    end

    test "replies with status error", %{socket: socket} do
      {query, params} = valid_query(:observation, "0")

      ref = push socket, "get_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply(ref, :error, %{errors: _ }, 1000)
    end
  end

  describe "update_observation" do
    test "replies with status ok and observation", %{socket: socket} do
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

      ref = push socket, "update_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply(
        ref,
        :ok,
        %{
          data: %{"observationMutationUpdate" =>
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
      )
    end

    test "replies with status error", %{socket: socket} do
      query = valid_query :observation_mutation_update

      params = %{
        "id" => "0",
        "comment" => "",
        "insertedAt" => "",
      }

      ref = push socket, "get_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply ref, :error, %{errors: _}
    end
  end
end
