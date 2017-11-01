defmodule IclogWeb.ObservationChannel do
  use IclogWeb, :channel

  alias IclogWeb.Schema

  def join("observation:observation", _params, socket) do
    {:ok, socket}
  end

  def handle_in( "new_observation", %{ "with_meta" => _, "query" => mutation }, socket) do
    reply = case Absinthe.run(mutation, Schema) do
       {:ok, %{data: data}} -> {:ok,  %{data: data}}
       {:ok, %{errors: error}} -> {:error, %{errors: error}}
    end
    {:reply, reply, socket}
  end
end
