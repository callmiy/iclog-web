defmodule Iclog.Schema do
  use Absinthe.Schema

  import_types Iclog.Observable.Schema.Observation
  import_types Iclog.Observable.Schema.ObservationMeta

  query do
    import_fields :observation_query
  end

  mutation do
    import_fields :Observation_mutation_with_meta
  end
end