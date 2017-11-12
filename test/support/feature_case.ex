defmodule Iclog.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Hound.Helpers

      import IclogWeb.Router.Helpers
      import Iclog.Factory
      import Iclog.FeatureCase

      @endpoint IclogWeb.Endpoint

      def assert_controls_empty(controls) do
        Enum.each controls, fn(control) ->
          assert attribute_value(control, "value") == ""
        end
      end
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Iclog.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Iclog.Repo, {:shared, self()})
    end

    metadata = Phoenix.Ecto.SQL.Sandbox.metadata_for(Iclog.Repo, self())
    chrome_args = [
      "--user-agent=#{Hound.Browser.user_agent(:chrome) |> Hound.Metadata.append(metadata)}",
      "--disable-gpu"
      ]

    chrome_args = unless tags[:no_headless] do
      ["--headless" | chrome_args]
    else
      chrome_args
    end

    additional_capabilities = %{
      chromeOptions: %{ "args" => chrome_args}
    }

    Hound.start_session(
      metadata: metadata,
      additional_capabilities: additional_capabilities
    )
    parent = self()
    on_exit(fn -> Hound.end_session(parent) end)

    :ok
  end

  def base_url do
    # "http://localhost:4014"
    "/"
  end

  def error_string(:lt, length) do
    "ShorterStringThan #{length}"
  end

  def wait_for_condition(condition, fun, args, timeout \\ 10000) do
    if condition == apply(fun, args) do
      condition
    else
      stop = System.monotonic_time(:millisecond) + timeout
      wait_for_condition(:loop, condition, fun, args, timeout, stop)
    end
  end
  defp wait_for_condition(:loop, condition, fun, args, timeout, stop) do
    new_condition = apply(fun, args)
    now = System.monotonic_time :millisecond

    if condition == new_condition || (now - stop) >= timeout  do
      new_condition
    else
      wait_for_condition(:loop, condition, fun, args, timeout, stop)
    end
  end
end
