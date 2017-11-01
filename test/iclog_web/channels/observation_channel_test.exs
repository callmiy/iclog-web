defmodule IclogWeb.ObservationChannelTest do
  use IclogWeb.ChannelCase

  import Iclog.Observable.Observation.TestHelper

  alias IclogWeb.ObservationChannel

  setup do
    {:ok, _, socket} =
      socket("user_id", %{some: :assign})
      |> subscribe_and_join(ObservationChannel, "observation:observation")

    {:ok, socket: socket}
  end

  test "new_observation replies with status ok, observation and meta", %{socket: socket} do
    ref = push socket, "new_observation", %{ 
      "with_meta" => "yes",
      "query" => valid_query(:Observation_mutation_with_meta)
    }

    assert_reply ref, :ok, %{data:  %{"observationWithMeta" => %{"id" => _, "meta" => _}}}, 300
  end

  test "new_observation replies with status error", %{socket: socket} do
    ref = push socket, "new_observation", %{ 
      "with_meta" => "yes",
      "query" => invalid_query(:Observation_mutation_with_meta)
    }

    assert_reply ref, :error, %{errors:  _}, 300
  end
end
