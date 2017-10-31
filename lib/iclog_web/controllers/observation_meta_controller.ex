defmodule IclogWeb.ObservationMetaController do
  use IclogWeb, :controller

  alias Iclog.ObservationMetas
  alias Iclog.ObservationMetas.ObservationMeta

  action_fallback IclogWeb.FallbackController

  def index(conn, _params) do
    observation_metas = ObservationMetas.list_observation_metas()
    render(conn, "index.json", observation_metas: observation_metas)
  end

  def create(conn, %{"observation_meta" => observation_meta_params}) do
    with {:ok, %ObservationMeta{} = observation_meta} <- ObservationMetas.create_observation_meta(observation_meta_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", observation_meta_path(conn, :show, observation_meta))
      |> render("show.json", observation_meta: observation_meta)
    end
  end

  def show(conn, %{"id" => id}) do
    observation_meta = ObservationMetas.get_observation_meta!(id)
    render(conn, "show.json", observation_meta: observation_meta)
  end

  def update(conn, %{"id" => id, "observation_meta" => observation_meta_params}) do
    observation_meta = ObservationMetas.get_observation_meta!(id)

    with {:ok, %ObservationMeta{} = observation_meta} <- ObservationMetas.update_observation_meta(observation_meta, observation_meta_params) do
      render(conn, "show.json", observation_meta: observation_meta)
    end
  end

  def delete(conn, %{"id" => id}) do
    observation_meta = ObservationMetas.get_observation_meta!(id)
    with {:ok, %ObservationMeta{}} <- ObservationMetas.delete_observation_meta(observation_meta) do
      send_resp(conn, :no_content, "")
    end
  end
end
