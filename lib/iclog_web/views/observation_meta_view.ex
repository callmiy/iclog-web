defmodule IclogWeb.ObservationMetaView do
  use IclogWeb, :view
  alias IclogWeb.ObservationMetaView

  def render("index.json", %{observation_metas: observation_metas}) do
    %{data: render_many(observation_metas, ObservationMetaView, "observation_meta.json")}
  end

  def render("show.json", %{observation_meta: observation_meta}) do
    %{data: render_one(observation_meta, ObservationMetaView, "observation_meta.json")}
  end

  def render("observation_meta.json", %{observation_meta: observation_meta}) do
    %{id: observation_meta.id,
      title: observation_meta.title,
      intro: observation_meta.intro}
  end
end
