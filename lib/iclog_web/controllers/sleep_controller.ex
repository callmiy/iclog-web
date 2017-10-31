defmodule IclogWeb.SleepController do
  use IclogWeb, :controller

  alias Iclog.Observable.Sleep

  action_fallback IclogWeb.FallbackController

  def index(conn, _params) do
    sleeps = Sleep.list()
    render(conn, "index.json", sleeps: sleeps)
  end

  def create(conn, %{"sleep" => sleep_params}) do
    with {:ok, %Sleep{} = sleep} <- Sleep.create(sleep_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", sleep_path(conn, :show, sleep))
      |> render("show.json", sleep: sleep)
    end
  end

  def show(conn, %{"id" => id}) do
    sleep = Sleep.get!(id)
    render(conn, "show.json", sleep: sleep)
  end

  def update(conn, %{"id" => id, "sleep" => sleep_params}) do
    sleep = Sleep.get!(id)

    with {:ok, %Sleep{} = sleep} <- Sleep.update(sleep, sleep_params) do
      render(conn, "show.json", sleep: sleep)
    end
  end

  def delete(conn, %{"id" => id}) do
    sleep = Sleep.get!(id)
    with {:ok, %Sleep{}} <- Sleep.delete(sleep) do
      send_resp(conn, :no_content, "")
    end
  end
end
