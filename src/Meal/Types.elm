module Meal.Types
    exposing
        ( MealWithComments
        , MealId
        , PaginatedMeals
        , Meal
        , fromMealId
        , toMealId
        , mealDecoder
        )

import Date exposing (Date)
import Utils exposing (Pagination)
import Json.Decode as Jd exposing (Decoder)
import Json.Decode.Extra as Jde exposing ((|:))
import Comment exposing (Comment)


type alias MealWithComments =
    { id : MealId
    , meal : String
    , time : Date
    , comments : List Comment
    }


type alias Meal =
    { id : MealId
    , meal : String
    , time : Date
    }


type alias PaginatedMeals =
    { entries : List Meal
    , pagination : Pagination
    }


type MealId
    = MealId String


fromMealId : MealId -> String
fromMealId (MealId id_) =
    id_


toMealId : String -> MealId
toMealId id_ =
    MealId id_


mealDecoder : Decoder Meal
mealDecoder =
    Jd.succeed Meal
        |: (Jd.field "id" <| Jd.map toMealId Jd.string)
        |: (Jd.field "meal" Jd.string)
        |: (Jd.field "time" Jde.date)
