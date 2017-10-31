defmodule Iclog.ObservableTest do
    use Iclog.DataCase

    alias Iclog.Observable.Meal

    @valid_attrs %{
      meal: "rice",
      comment: "some comment",
      time: "2010-04-17T14:00:00.000000Z"
    }
    
    @update_attrs %{
      meal: "potato",
      comment: "some updated comment",
      time: "2011-05-18T15:01:01.000000Z"
    }

    @invalid_attrs %{
      meal: nil,
      comment: nil, 
      time: nil
    }

    def meal_fixture(attrs \\ %{}) do
      {:ok, meal} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Meal.create()

      meal
    end

    test "list/0 returns all meals" do
      meal = meal_fixture()
      assert Meal.list() == [meal]
    end

    test "get!/1 returns the meal with given id" do
      meal = meal_fixture()
      assert Meal.get!(meal.id) == meal
    end

    test "create/1 with valid data creates a meal" do
      assert {:ok, %Meal{} = meal} = Meal.create(@valid_attrs)
      assert meal.meal == "rice"
      assert meal.comment == "some comment"
      assert meal.time == DateTime.from_naive!(~N[2010-04-17T14:00:00.000000Z], "Etc/UTC")
    end

    test "create/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Meal.create(@invalid_attrs)
    end

    test "update/2 with valid data updates the meal" do
      meal = meal_fixture()
      assert {:ok, meal} = Meal.update(meal, @update_attrs)
      assert %Meal{} = meal
      assert meal.meal == "potato"
      assert meal.comment == "some updated comment"
      assert meal.time == DateTime.from_naive!(~N[2011-05-18T15:01:01.000000Z], "Etc/UTC")
    end

    test "update/2 with invalid data returns error changeset" do
      meal = meal_fixture()
      assert {:error, %Ecto.Changeset{}} = Meal.update(meal, @invalid_attrs)
      assert meal == Meal.get!(meal.id)
    end

    test "delete/1 deletes the meal" do
      meal = meal_fixture()
      assert {:ok, %Meal{}} = Meal.delete(meal)
      assert_raise Ecto.NoResultsError, fn -> Meal.get!(meal.id) end
    end

    test "change/1 returns a meal changeset" do
      meal = meal_fixture()
      assert %Ecto.Changeset{} = Meal.change(meal)
    end
  
end
