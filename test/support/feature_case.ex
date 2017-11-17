defmodule Iclog.FeatureCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Hound.Helpers

      alias Iclog.Repo

      import IclogWeb.Router.Helpers
      import Iclog.Factory
      import Iclog.FeatureCase

      @endpoint IclogWeb.Endpoint

      def assert_controls_empty(controls) do
        Enum.each controls, fn(control) ->
          assert wait_for_condition(
            true,
            fn() ->
              attribute_value(control, "value") == ""
            end,
            []
          )
        end
      end

      def type_text(text_, delay \\ 10, element_ \\ nil) do
        if element_, do: click element_

        Enum.each String.graphemes(text_), fn(text) ->
          send_text text
          :timer.sleep delay
        end
      end

      def control_validate_string_lenght(ops) do
        control_validate_string_lenght(:no_valid_text, ops)

        # And when user inputs ops.string_len or more characters into ops.field,
        fill_field(ops.field, ops.valid_text)

        # the error message disappears
        refute element?(:id, ops.error_id)

        # and control's border color changes to green
        refute has_class?(ops.field, "is-invalid")
        assert has_class?(ops.field, "is-valid")
      end
      def control_validate_string_lenght(:no_valid_text, ops) do
        # When user inputs less than ops.string_len characters into ops.field,
        # the color of the field's border changes to "#dc3545" (some kind of red)
        fill_field(ops.field, ops.invalid_text)
        assert wait_for_condition(true, &has_class?/2, [ops.field, "is-invalid"])

        # And a red colored line of text appears indicating to
        # user that the input is less than ops.string_len characters
        error_text = Map.get(ops, :error_text) || error_string(:lt, ops.string_len)
        assert visible_text({:id, ops.error_id}) == error_text
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

  def wait_for_condition(condition, fun, args \\ [], timeout \\ 10000) do
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
