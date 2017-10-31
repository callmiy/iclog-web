defmodule IclogWeb.SleepView do
  use IclogWeb, :view
  alias IclogWeb.SleepView

  def render("index.json", %{sleeps: sleeps}) do
    %{data: render_many(sleeps, SleepView, "sleep.json")}
  end

  def render("show.json", %{sleep: sleep}) do
    %{data: render_one(sleep, SleepView, "sleep.json")}
  end

  def render("sleep.json", %{sleep: sleep}) do
    %{id: sleep.id,
      start: sleep.start,
      end: sleep.end,
      comment: sleep.comment}
  end
end
