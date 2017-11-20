module Store
    exposing
        ( Store
        , Flag
        , TimeZoneOffset
        , getWebsocketUrl
        , create
        , getTimeZoneOffset
        , toTimeZoneVal
        , getPaginatedObservations
        , updatePaginatedObservations
        , addObservation
        , updateObservation
        , getPaginatedMeals
        , updatePaginatedMeals
        , addMeal
        , updateMeal
        )

import Observation.Types
    exposing
        ( PaginatedObservations
        , Observation
        )
import Utils
    exposing
        ( defaultPagination
        , updatePaginationEntriesBy
        )
import Meal.Types
    exposing
        ( PaginatedMeals
        , MealListOnly
        )


type alias Flag =
    { apiUrl : Maybe String
    , websocketUrl : Maybe String
    , timeZoneOffset : Int
    }


type TimeZoneOffset
    = TimeZoneOffset Int


type Store
    = Store
        { apiUrl : Maybe String
        , websocketUrl : Maybe String
        , timeZoneOffset : TimeZoneOffset
        , paginatedObservations : PaginatedObservations
        , paginatedMeals : PaginatedMeals
        }


create : Flag -> Store
create { apiUrl, websocketUrl, timeZoneOffset } =
    Store
        { apiUrl = apiUrl
        , websocketUrl = websocketUrl
        , timeZoneOffset = TimeZoneOffset timeZoneOffset
        , paginatedObservations =
            { entries = []
            , pagination = defaultPagination
            }
        , paginatedMeals =
            { entries = []
            , pagination = defaultPagination
            }
        }


getWebsocketUrl : Store -> Maybe String
getWebsocketUrl (Store { websocketUrl }) =
    websocketUrl


getTimeZoneOffset : Store -> TimeZoneOffset
getTimeZoneOffset (Store { timeZoneOffset }) =
    timeZoneOffset


toTimeZoneVal : TimeZoneOffset -> Int
toTimeZoneVal (TimeZoneOffset val) =
    val


getPaginatedObservations : Store -> PaginatedObservations
getPaginatedObservations (Store { paginatedObservations }) =
    paginatedObservations


updatePaginatedObservations : PaginatedObservations -> Store -> Store
updatePaginatedObservations pobs (Store store) =
    Store { store | paginatedObservations = pobs }


addObservation : Observation -> Store -> Store
addObservation obs store =
    let
        { entries, pagination } =
            getPaginatedObservations store

        pobs =
            { entries = obs :: entries |> List.take pagination.pageSize
            , pagination = updatePaginationEntriesBy 1 pagination
            }
    in
        updatePaginatedObservations pobs store


updateObservation : Observation -> Store -> Store
updateObservation ({ id } as obs) store =
    let
        { entries, pagination } =
            getPaginatedObservations store

        otherObs =
            List.filter (\o -> o.id /= id) entries

        posb =
            { entries = obs :: otherObs
            , pagination = pagination
            }
    in
        updatePaginatedObservations posb store


getPaginatedMeals : Store -> PaginatedMeals
getPaginatedMeals (Store { paginatedMeals }) =
    paginatedMeals


updatePaginatedMeals : PaginatedMeals -> Store -> Store
updatePaginatedMeals pobs (Store store) =
    Store { store | paginatedMeals = pobs }


addMeal : MealListOnly -> Store -> Store
addMeal meal store =
    let
        { entries, pagination } =
            getPaginatedMeals store

        pml =
            { entries = meal :: entries |> List.take pagination.pageSize
            , pagination = updatePaginationEntriesBy 1 pagination
            }
    in
        updatePaginatedMeals pml store


updateMeal : MealListOnly -> Store -> Store
updateMeal ({ id } as meal) store =
    let
        { entries, pagination } =
            getPaginatedMeals store

        otherMeals =
            List.filter (\m -> m.id /= id) entries

        pmls =
            { entries = meal :: otherMeals
            , pagination = pagination
            }
    in
        updatePaginatedMeals pmls store
