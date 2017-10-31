defmodule Iclog.Observable.Observation.TestHelper do
  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta.TestHelper, as: ObservationMetaHelper

  def valid_attrs(:no_meta) do
    %{comment: "some comment"}
  end

  def valid_attrs do
    meta = ObservationMetaHelper.fixture()
    %{comment: "some comment", observation_meta_id: meta.id}
  end 

  def update_attrs do
    %{comment: "some updated comment"}
  end 

  def invalid_attrs do
    %{}
  end

  def fixture(attrs \\ nil) do
    attrs = if attrs == nil, do: valid_attrs(), else: attrs
    
    {:ok, observation} = Observation.create(attrs)

    observation
  end
end