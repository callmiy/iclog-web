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
        )

import Observation.Types exposing (PaginatedObservations, Observation)
import Utils exposing (defaultPagination, updatePaginationEntriesBy)


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

        posb =
            { entries = obs :: entries |> List.take pagination.pageSize
            , pagination = updatePaginationEntriesBy 1 pagination
            }
    in
        updatePaginatedObservations posb store


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
