defmodule IclogWeb.MealControllerTest do
  use IclogWeb.ConnCase

  alias Iclog.Observable.Meal

  @create_attrs %{
    comment: "some comment", 
    time: "2010-04-17T14:00:00.000000Z",
    meal: "rice"
  }
  
  @update_attrs %{
    comment: "some updated comment",
    time: "2011-05-18T15:01:01.000000Z",
    meal: "potato"
  }
  
  @invalid_attrs %{
    comment: nil,
    time: nil,
    meal: nil
  }

  def fixture(:meal) do
    {:ok, meal} = Meal.create(@create_attrs)
    meal
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all meals", %{conn: conn} do
      conn = get conn, meal_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create meal" do
    test "renders meal when data is valid", %{conn: conn} do
      conn = post conn, meal_path(conn, :create), meal: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, meal_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "meal" => "rice",
        "comment" => "some comment",
        "time" => "2010-04-17T14:00:00.000000Z"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, meal_path(conn, :create), meal: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update meal" do
    setup [:create]

    test "renders meal when data is valid", %{conn: conn, meal: %Meal{id: id} = meal} do
      conn = put conn, meal_path(conn, :update, meal), meal: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, meal_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "meal" => "potato",
        "comment" => "some updated comment",
        "time" => "2011-05-18T15:01:01.000000Z"}
    end

    test "renders errors when data is invalid", %{conn: conn, meal: meal} do
      conn = put conn, meal_path(conn, :update, meal), meal: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete meal" do
    setup [:create]

    test "deletes chosen meal", %{conn: conn, meal: meal} do
      conn = delete conn, meal_path(conn, :delete, meal)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, meal_path(conn, :show, meal)
      end
    end
  end

  defp create(_) do
    meal = fixture(:meal)
    {:ok, meal: meal}
  end
end
