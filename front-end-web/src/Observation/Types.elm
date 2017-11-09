module Observation.Types
    exposing
        ( Observation
        , Meta
        , CreateMeta
        , CreateObservationWithMeta
        , emptyString
        , emptyMeta
        , emptyCreateMeta
        )


type alias Observation =
    { id : String
    , comment : String
    , meta : Meta
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
