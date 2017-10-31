defmodule Iclog.Observable.WeightTest do
    use Iclog.DataCase

    alias Iclog.Observable.Weight

    @valid_attrs %{weight: 120.5}
    @update_attrs %{weight: 456.7}
    @invalid_attrs %{weight: nil}

    def fixture(attrs \\ %{}) do
      {:ok, weight} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Weight.create()

      weight
    end

    test "list/0 returns all weights" do
      weight = fixture()
      assert Weight.list() == [weight]
    end

    test "get!/1 returns the weight with given id" do
      weight = fixture()
      assert Weight.get!(weight.id) == weight
    end

    test "create/1 with valid data creates a weight" do
      assert {:ok, %Weight{} = weight} = Weight.create(@valid_attrs)
      assert weight.weight == 120.5
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Weight.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the weight" do
      weight = fixture()
      assert {:ok, weight} = Weight.update(weight, @update_attrs)
      assert %Weight{} = weight
      assert weight.weight == 456.7
    end

    test "update/2 with invalid data returns error changeset" do
      weight = fixture()
      assert {:error, %Ecto.Changeset{}} = Weight.update(weight, @invalid_attrs)
      assert weight == Weight.get!(weight.id)
    end

    test "delete/1 deletes the weight" do
      weight = fixture()
      assert {:ok, %Weight{}} = Weight.delete(weight)
      assert_raise Ecto.NoResultsError, fn -> Weight.get!(weight.id) end
    end

    test "change/1 returns a weight changeset" do
      weight = fixture()
      assert %Ecto.Changeset{} = Weight.change(weight)
    end
  
end
