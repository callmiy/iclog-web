defmodule IclogWeb.ObservationView do
  use IclogWeb, :view
  alias IclogWeb.ObservationView

  def render("index.json", %{observations: observations}) do
    %{data: render_many(observations, ObservationView, "observation.json")}
  end

  def render("show.json", %{observation: observation}) do
    %{data: render_one(observation, ObservationView, "observation.json")}
  end

  def render("observation.json", %{observation: observation}) do
    %{id: observation.id,
      comment: observation.comment}
  end
end
