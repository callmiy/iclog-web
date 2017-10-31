defmodule IclogWeb.WeightControllerTest do
  use IclogWeb.ConnCase

  alias Iclog.Observable.Weight

  @create_attrs %{weight: 120.5}
  @update_attrs %{weight: 456.7}
  @invalid_attrs %{weight: nil}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all weights", %{conn: conn} do
      conn = get conn, weight_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create weight" do
    test "renders weight when data is valid", %{conn: conn} do
      conn = post conn, weight_path(conn, :create), weight: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, weight_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "weight" => 120.5}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, weight_path(conn, :create), weight: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update weight" do
    setup [:create]

    test "renders weight when data is valid", 
        %{conn: conn, weight: %Weight{id: id} = weight} do
      conn = put conn, weight_path(conn, :update, weight), weight: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, weight_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "weight" => 456.7}
    end

    test "renders errors when data is invalid", %{conn: conn, weight: weight} do
      conn = put conn, weight_path(conn, :update, weight), weight: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete weight" do
    setup [:create]

    test "deletes chosen weight", %{conn: conn, weight: weight} do
      conn = delete conn, weight_path(conn, :delete, weight)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, weight_path(conn, :show, weight)
      end
    end
  end

  defp create(_) do
    {:ok, weight} = Weight.create(@create_attrs)
    {:ok, weight: weight}
  end
end
