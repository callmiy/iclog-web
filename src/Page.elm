module Page
    exposing
        ( Page(..)
        , PageState(..)
        , getPage
        )

import Observation.Detail.App as ObservationDetail
import Observation.List as ObservationList
import Observation.New.App as ObservationNew
import Meal.Detail.App as MealDetail
import Meal.List as MealList
import Meal.New as MealNew
import Sleep.List as SleepList
import Sleep.New as SleepNew
import Sleep.Detail.App as SleepDetail


type Page
    = Blank
    | ObservationDetail ObservationDetail.Model
    | ObservationList ObservationList.Model
    | ObservationNew ObservationNew.Model
    | MealDetail MealDetail.Model
    | MealList MealList.Model
    | MealNew MealNew.Model
    | SleepList SleepList.Model
    | SleepNew SleepNew.Model
    | SleepDetail SleepDetail.Model


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
