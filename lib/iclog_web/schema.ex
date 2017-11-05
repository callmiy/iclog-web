defmodule IclogWeb.Schema do
  use Absinthe.Schema

  import_types IclogWeb.Schema.Helpers
  import_types IclogWeb.Schema.Observation
  import_types IclogWeb.Schema.ObservationMeta

  query do
    import_fields :observation_query
  end

  mutation do
    import_fields :Observation_mutation_with_meta
  end
end