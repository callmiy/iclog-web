defmodule IclogWeb.Schema do
  use Absinthe.Schema

  import_types IclogWeb.Schema.Types
  import_types IclogWeb.Schema.Observation
  import_types IclogWeb.Schema.ObservationMeta

  query do
    import_fields :observation_query
    import_fields :observation_meta_query
  end

  mutation do
    import_fields :Observation_mutations
  end
end