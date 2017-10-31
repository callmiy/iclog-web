defmodule Iclog.Observable.SleepTest do
    use Iclog.DataCase
    import Iclog.Observable.Sleep.Helper

    alias Iclog.Observable.Sleep

    @update_attrs %{comment: "some updated comment", end: "2011-05-18 15:01:01.000000Z", start: "2011-05-18 15:01:01.000000Z"}
    @invalid_attrs %{comment: nil, end: nil, start: nil}

    

    def sleep_fixture(attrs \\ %{}) do
      {:ok, sleep} =
        attrs
        |> Enum.into(valid_attrs())
        |> Sleep.create()

      sleep
    end

    test "list/0 returns all sleeps" do
      sleep = sleep_fixture()
      assert Sleep.list() == [sleep]
    end

    test "get!/1 returns the sleep with given id" do
      sleep = sleep_fixture()
      assert Sleep.get!(sleep.id) == sleep
    end

    test "create/1 with valid data creates a sleep" do
      valid = valid_attrs()
      assert {:ok, %Sleep{} = sleep} = Sleep.create(valid)
      assert sleep.comment == "some comment"
      assert format_time(sleep.end) == valid.end
      assert format_time(sleep.start) == valid.start
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sleep.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the sleep" do
      sleep = sleep_fixture()
      assert {:ok, sleep} = Sleep.update(sleep, @update_attrs)
      assert %Sleep{} = sleep
      assert sleep.comment == "some updated comment"
      assert sleep.end == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
      assert sleep.start == DateTime.from_naive!(~N[2011-05-18 15:01:01.000000Z], "Etc/UTC")
    end

    test "update/2 with invalid data returns error changeset" do
      sleep = sleep_fixture()
      assert {:error, %Ecto.Changeset{}} = Sleep.update(sleep, @invalid_attrs)
      assert sleep == Sleep.get!(sleep.id)
    end

    test "delete/1 deletes the sleep" do
      sleep = sleep_fixture()
      assert {:ok, %Sleep{}} = Sleep.delete(sleep)
      assert_raise Ecto.NoResultsError, fn -> Sleep.get!(sleep.id) end
    end

    test "change/1 returns a sleep changeset" do
      sleep = sleep_fixture()
      assert %Ecto.Changeset{} = Sleep.change(sleep)
    end
end
