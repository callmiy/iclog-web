defmodule IclogWeb.SleepControllerTest do
  use IclogWeb.ConnCase
  import Iclog.Observable.Sleep.Helper

  alias Iclog.Observable.Sleep

  @invalid_attrs %{comment: nil, end: nil, start: nil}

  def fixture(:sleep) do
    {:ok, sleep} = Sleep.create(valid_attrs())
    sleep
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all sleeps", %{conn: conn} do
      conn = get conn, sleep_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create sleep" do
    test "renders sleep when data is valid", %{conn: conn} do
      valid = valid_attrs()

      conn = post conn, sleep_path(conn, :create), sleep: valid
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, sleep_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "comment" => "some comment",
        "end" => valid.end,
        "start" => valid.start}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, sleep_path(conn, :create), sleep: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update sleep" do
    setup [:create_sleep]

    test "renders sleep when data is valid", %{conn: conn, sleep: %Sleep{id: id} = sleep} do
      valid = update_attrs()

      conn = put conn, sleep_path(conn, :update, sleep), sleep: valid
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, sleep_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "comment" => "some updated comment",
        "end" => valid.end,
        "start" => valid.start}
    end

    test "renders errors when data is invalid", %{conn: conn, sleep: sleep} do
      conn = put conn, sleep_path(conn, :update, sleep), sleep: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete sleep" do
    setup [:create_sleep]

    test "deletes chosen sleep", %{conn: conn, sleep: sleep} do
      conn = delete conn, sleep_path(conn, :delete, sleep)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, sleep_path(conn, :show, sleep)
      end
    end
  end

  defp create_sleep(_) do
    sleep = fixture(:sleep)
    {:ok, sleep: sleep}
  end
end
