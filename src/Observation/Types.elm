module Observation.Types
    exposing
        ( Observation
        , Meta
        , CreateMeta
        , CreateObservationWithMeta
        , PaginatedObservations
        , emptyString
        , emptyMeta
        , emptyCreateMeta
        )

import Date exposing (Date)
import Utils exposing (Pagination)


type alias Observation =
    { id : String
    , comment : String
    , meta : Meta
    , insertedAt : Date
    }


type alias PaginatedObservations =
    { entries : List Observation
    , pagination : Pagination
    }


type alias CreateObservationWithMeta =
    { comment : String
    , meta : CreateMeta
    }


type alias Meta =
    { id : String
    , title : String
    }


type alias CreateMeta =
    { title : String
    , intro : Maybe String
    }


emptyString : String
emptyString =
    ""


emptyMeta : Meta
emptyMeta =
    { id = "0"
    , title = emptyString
    }


emptyCreateMeta : CreateMeta
emptyCreateMeta =
    { title = emptyString
    , intro = Nothing
    }
