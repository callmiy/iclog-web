defmodule IclogWeb.ObservationMetaControllerTest do
  use IclogWeb.ConnCase
  import Iclog.Observable.ObservationMeta.TestHelper

  alias Iclog.Observable.ObservationMeta

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all observation_metas", %{conn: conn} do
      conn = get conn, observation_meta_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create observation_meta" do
    test "renders observation_meta when data is valid", %{conn: conn} do
      conn = post conn, observation_meta_path(conn, :create), observation_meta: valid_attrs()
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, observation_meta_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "intro" => "some intro",
        "title" => "some title"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, observation_meta_path(conn, :create), observation_meta: invalid_attrs()
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update observation_meta" do
    setup [:create]

    test "renders observation_meta when data is valid",
        %{conn: conn, observation_meta: %ObservationMeta{id: id} = observation_meta} do
      conn = put conn, observation_meta_path(conn, :update, observation_meta), observation_meta: update_attrs()
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, observation_meta_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "intro" => "some updated intro",
        "title" => "some updated title"}
    end

    test "renders errors when data is invalid", %{conn: conn, observation_meta: observation_meta} do
      conn = put conn, observation_meta_path(conn, :update, observation_meta), observation_meta: invalid_attrs()
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete observation_meta" do
    setup [:create]

    test "deletes chosen observation_meta", %{conn: conn, observation_meta: observation_meta} do
      conn = delete conn, observation_meta_path(conn, :delete, observation_meta)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, observation_meta_path(conn, :show, observation_meta)
      end
    end
  end

  defp create(_) do
    meta = fixture()
    {:ok, observation_meta: meta}
  end
end
