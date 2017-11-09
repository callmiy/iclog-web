defmodule IclogWeb.ObservationChannelTest do
  use IclogWeb.ChannelCase

  import Iclog.Observable.Observation.TestHelper

  alias IclogWeb.ObservationChannel
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObmHelper

  defp init(_) do
    {:ok, _, socket} =
    socket("user_id", %{some: :assign})
    |> subscribe_and_join(ObservationChannel, "observation:observation")

    {:ok, socket: socket}
  end

  describe "new_observation" do
    setup([:init])

    test "new_observation with_meta replies with status ok, observation and meta", %{socket: socket} do
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

    test "new_observation with_meta replies with status error", %{socket: socket} do
      {query, params} = invalid_query(:Observation_mutation_with_meta)

      ref = push socket, "new_observation", %{
        "with_meta" => "yes",
        "query" => query,
        "params" => params
      }

      assert_reply ref, :error, %{errors:  _}, 1000
    end

    test "new_observation replies with status ok, observation and meta", %{socket: socket} do
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

    test "new_observation replies with status error", %{socket: socket} do
      {query, params} = valid_query(:Observation_mutation, 0)

      ref = push socket, "new_observation", %{
        "query" => query,
        "params" => params
      }

      assert_reply ref, :error, %{errors:  _}, 1000
    end
  end

  describe "search_metas_by_title" do
    setup([:init])

    test "search_metas_by_title replies with status ok and  metas", %{socket: socket} do
      fixture(valid_attrs(:with_meta))

      {query, params} = ObmHelper.valid_query(:observation_metas_by_title_query)

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
end
