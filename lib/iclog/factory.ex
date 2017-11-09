defmodule Iclog.Factory do
  use ExMachina.Ecto, repo: Iclog.Repo

  alias Iclog.Observable.Observation
  alias Iclog.Observable.ObservationMeta

  def observation_meta_factory do
    %ObservationMeta{
      title: sequence("some title"),
      intro: sequence("some intro"),
    }
  end

  def observation_factory do
    %Observation{
      comment: sequence("some comment"),
      observation_meta: build(:observation_meta),
    }
  end
end