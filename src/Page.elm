module Page
    exposing
        ( Page(..)
        , PageState(..)
        , getPage
        )

import Observation.Detail.App as ObservationDetail
import Observation.List as ObservationList
import Observation.New.App as ObservationNew
import Meal.Detail as MealDetail
import Meal.List as MealList
import Meal.New as MealNew


type Page
    = Blank
    | ObservationDetail ObservationDetail.Model
    | ObservationList ObservationList.Model
    | ObservationNew ObservationNew.Model
    | MealDetail MealDetail.Model
    | MealList MealList.Model
    | MealNew MealNew.Model


type PageState
    = Loaded Page
    | RedirectingTo Page


getPage : PageState -> Page
getPage p =
    case p of
        Loaded page ->
            page

        RedirectingTo page ->
            page
