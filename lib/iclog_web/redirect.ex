defmodule IclogWeb.Redictor do
  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    if List.first(conn.path_info) == "api" do
      conn
    else
      conn
      |> Plug.Conn.put_resp_header("location", "/")
      |> Plug.Conn.resp(301, "You are being redirected.")
      |> Plug.Conn.halt
    end
  end
end
