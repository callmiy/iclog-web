defmodule IclogWeb.Schema.Types do
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

  object :pagination do
    field :page_number, non_null(:integer)
    field :page_size, non_null(:integer)
    field :total_pages, non_null(:integer)
    field :total_entries, non_null(:integer)
  end

  input_object :pagination_params do
    field :page, non_null(:integer)
    field :page_size, :integer
  end
end