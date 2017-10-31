defmodule IclogWeb.Router do
  use IclogWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", IclogWeb do

  end

  # Other scopes may use custom stacks.
  # scope "/api", IclogWeb do
  #   pipe_through :api
  # end
end
