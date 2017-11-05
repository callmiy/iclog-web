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

  def valid_query(:observation_query) do
    """
    {
      observations {
        id
        comment
        insertedAt
        updatedAt
        meta {
          id
          title
          intro
        }
      }
    }
    """
  end

  def valid_query(:Observation_mutation_with_meta) do
    query = """
      mutation createObservationAndMeta ($comment: String!, $meta: Meta!) {
        observationWithMeta(
          comment: $comment,
          meta: $meta
        ) {
          id
          meta {
            id
          }
        }
      }
    """

    params = %{
      "comment" => "some comment",
      "meta" => %{"title" => "nice title"}
    }

    {query, params}
  end

  def invalid_query(:Observation_mutation_with_meta) do
    query = """
      mutation createObservationAndMeta ($comment: String!, $meta: Meta!) {
        observationWithMeta(
          comment: $comment,
          meta: $meta
        ) {
          id
          meta {
            id
          }
        }
      }
    """

    params = %{
      "comment" => "some comment"
    }

    {query, params}
  end
end