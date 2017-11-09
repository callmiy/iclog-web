defmodule IclogWeb.ObservationControllerTest do
  use IclogWeb.ConnCase
  import Iclog.Observable.Observation.TestHelper

  alias Iclog.Observable.Observation

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all observations", %{conn: conn} do
      conn = get conn, observation_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create observation" do
    test "renders observation when data is valid", %{conn: conn} do
      conn = post conn, observation_path(conn, :create), observation: valid_attrs(:with_meta)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, observation_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "comment" => "some comment"}
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, observation_path(conn, :create), observation: invalid_attrs()
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update observation" do
    setup [:create]

    test "renders observation when data is valid", 
        %{conn: conn, observation: %Observation{id: id} = observation} do
      conn = put conn, observation_path(conn, :update, observation), observation: update_attrs()
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, observation_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "comment" => "some updated comment"}
    end
  end

  describe "delete observation" do
    setup [:create]

    test "deletes chosen observation", %{conn: conn, observation: observation} do
      conn = delete conn, observation_path(conn, :delete, observation)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, observation_path(conn, :show, observation)
      end
    end
  end

  defp create(_) do
    {:ok, observation} = Observation.create(valid_attrs(:with_meta))
    {:ok, observation: observation}
  end
end
