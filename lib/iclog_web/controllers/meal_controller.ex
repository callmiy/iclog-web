defmodule IclogWeb.MealController do
  use IclogWeb, :controller

  alias Iclog.Observable.Meal

  action_fallback IclogWeb.FallbackController

  def index(conn, _params) do
    meals = Meal.list()
    render(conn, "index.json", meals: meals)
  end

  def create(conn, %{"meal" => meal_params}) do
    with {:ok, %Meal{} = meal} <- Meal.create(meal_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", meal_path(conn, :show, meal))
      |> render("show.json", meal: meal)
    end
  end

  def show(conn, %{"id" => id}) do
    meal = Meal.get!(id)
    render(conn, "show.json", meal: meal)
  end

  def update(conn, %{"id" => id, "meal" => meal_params}) do
    meal = Meal.get!(id)

    with {:ok, %Meal{} = meal} <- Meal.update(meal, meal_params) do
      render(conn, "show.json", meal: meal)
    end
  end

  def delete(conn, %{"id" => id}) do
    meal = Meal.get!(id)
    with {:ok, %Meal{}} <- Meal.delete(meal) do
      send_resp(conn, :no_content, "")
    end
  end
end
