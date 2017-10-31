defmodule IclogWeb.WeightController do
  use IclogWeb, :controller

  alias Iclog.Observable.Weight

  action_fallback IclogWeb.FallbackController

  def index(conn, _params) do
    weights = Weight.list()
    render(conn, "index.json", weights: weights)
  end

  def create(conn, %{"weight" => weight_params}) do
    with {:ok, %Weight{} = weight} <- Weight.create(weight_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", weight_path(conn, :show, weight))
      |> render("show.json", weight: weight)
    end
  end

  def show(conn, %{"id" => id}) do
    weight = Weight.get!(id)
    render(conn, "show.json", weight: weight)
  end

  def update(conn, %{"id" => id, "weight" => weight_params}) do
    weight = Weight.get!(id)

    with {:ok, %Weight{} = weight} <- Weight.update(weight, weight_params) do
      render(conn, "show.json", weight: weight)
    end
  end

  def delete(conn, %{"id" => id}) do
    weight = Weight.get!(id)
    with {:ok, %Weight{}} <- Weight.delete(weight) do
      send_resp(conn, :no_content, "")
    end
  end
end
