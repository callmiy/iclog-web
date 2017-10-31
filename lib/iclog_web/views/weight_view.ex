defmodule IclogWeb.WeightView do
  use IclogWeb, :view
  alias IclogWeb.WeightView

  def render("index.json", %{weights: weights}) do
    %{data: render_many(weights, WeightView, "weight.json")}
  end

  def render("show.json", %{weight: weight}) do
    %{data: render_one(weight, WeightView, "weight.json")}
  end

  def render("weight.json", %{weight: weight}) do
    %{id: weight.id,
      weight: weight.weight}
  end
end
