module Router
    exposing
        ( Route(..)
        , Msg
        , goto
        )

import Task


type Route
    = NotFound
    | ObservationDetail String
    | ObservationList
    | ObservationNew


type alias Msg msg =
    Route -> msg


goto : Route -> Msg msg -> Cmd msg
goto route tagger =
    Task.perform tagger <| Task.succeed route
