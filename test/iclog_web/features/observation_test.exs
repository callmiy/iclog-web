defmodule IclogWeb.Features.ObservationTest do
  use Iclog.FeatureCase, async: true

  @tag :integration
  test "checking out wallaby", %{session: session} do
    session
    |> visit("/")
    # |> find(Query.css("#new-observation-icon"))
    |> assert_has(Query.css(".global-title", text: "Observables"))
  end
end