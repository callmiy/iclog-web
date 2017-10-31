defmodule IclogWeb.PageController do
  use IclogWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
