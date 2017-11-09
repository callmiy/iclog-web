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

  def valid_query(:observation_metas_query) do
    """
    {
      observationMetas {
        id
        title
        intro
        inserted_at
        updated_at
        observations {
          id
          comment
        }
      }
    }
    """
  end
  def valid_query(:observation_metas_by_title_query) do
    query = """
    {
      observationMetasByTitle(title: "som") {
        id
        title
        intro
        inserted_at
        updated_at
        observations {
          id
          comment
        }
      }
    }
    """

    params = %{"title" => valid_attrs()[:title]}

    {query, params}
  end
end