defmodule IclogWeb.ObservationMetaController do
  use IclogWeb, :controller

  alias Iclog.Observable.ObservationMeta

  action_fallback IclogWeb.FallbackController

  def index(conn, _params) do
    metas = ObservationMeta.list()
    render(conn, "index.json", observation_metas: metas)
  end

  def create(conn, %{"observation_meta" => params}) do
    with {:ok, %ObservationMeta{} = meta} <- ObservationMeta.create(params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", observation_meta_path(conn, :show, meta))
      |> render("show.json", observation_meta: meta)
    end
  end

  def show(conn, %{"id" => id}) do
    meta = ObservationMeta.get!(id)
    render(conn, "show.json", observation_meta: meta)
  end

  def update(conn, %{"id" => id, "observation_meta" => params}) do
    meta = ObservationMeta.get!(id)

    with {:ok, %ObservationMeta{} = meta} <- ObservationMeta.update(meta, params) do
      render(conn, "show.json", observation_meta: meta)
    end
  end

  def delete(conn, %{"id" => id}) do
    meta = ObservationMeta.get!(id)
    with {:ok, %ObservationMeta{}} <- ObservationMeta.delete(meta) do
      send_resp(conn, :no_content, "")
    end
  end
end
