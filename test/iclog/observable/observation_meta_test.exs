defmodule Iclog.Observable.ObservationMetasTest do
  use Iclog.DataCase

  alias Iclog.Observable.ObservationMeta

    @valid_attrs %{intro: "some intro", title: "some title"}
    @update_attrs %{intro: "some updated intro", title: "some updated title"}
    @invalid_attrs %{intro: nil, title: nil}

    def fixture(attrs \\ %{}) do
      {:ok, meta} =
        attrs
        |> Enum.into(@valid_attrs)
        |> ObservationMeta.create()

      meta
    end

    test "list/0 returns all observation_metas" do
      meta = fixture()
      assert ObservationMeta.list() == [meta]
    end

    test "get!/1 returns the observation_meta with given id" do
      meta = fixture()
      assert ObservationMeta.get!(meta.id) == meta
    end

    test "create/1 with valid data creates a observation_meta" do
      assert {:ok, %ObservationMeta{} = meta} = ObservationMeta.create(@valid_attrs)
      assert meta.intro == "some intro"
      assert meta.title == "some title"
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = ObservationMeta.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the observation_meta" do
      meta = fixture()
      assert {:ok, meta} = ObservationMeta.update(meta, @update_attrs)
      assert %ObservationMeta{} = meta
      assert meta.intro == "some updated intro"
      assert meta.title == "some updated title"
    end

    test "update/2 with invalid data returns error changeset" do
      meta = fixture()
      assert {:error, %Ecto.Changeset{}} = ObservationMeta.update(meta, @invalid_attrs)
      assert meta == ObservationMeta.get!(meta.id)
    end

    test "delete/1 deletes the observation_meta" do
      meta = fixture()
      assert {:ok, %ObservationMeta{}} = ObservationMeta.delete(meta)
      assert_raise Ecto.NoResultsError, fn -> ObservationMeta.get!(meta.id) end
    end

    test "change/1 returns a observation_meta changeset" do
      meta = fixture()
      assert %Ecto.Changeset{} = ObservationMeta.change(meta)
    end
end
