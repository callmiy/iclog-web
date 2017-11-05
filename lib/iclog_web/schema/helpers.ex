defmodule IclogWeb.Schema.Helpers do
  use Absinthe.Schema.Notation

  scalar :timex_datetime, description: "{ISO:Extended:Z}" do
    parse (fn(value) ->
            case DateTime.from_iso8601(value) do
              {:ok, val, _} -> {:ok, val}
              {:error, _} -> :error
            end
          end)
    
    serialize &Timex.format!(&1, "{ISO:Extended:Z}")
  end
end