defmodule Iclog.Observable.ObservationMeta.TestHelper do
  alias Iclog.Observable.ObservationMeta

  def valid_attrs do
    %{intro: "some intro", title: "some title"}
  end 

  def update_attrs do
    %{intro: "some updated intro", title: "some updated title"}
  end 

  def invalid_attrs do
    %{intro: nil, title: nil}
  end 

  def fixture(attrs \\ %{}) do
    {:ok, meta} =
      attrs
      |> Enum.into(valid_attrs())
      |> ObservationMeta.create()

    meta
  end
end