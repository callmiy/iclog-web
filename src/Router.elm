module Router
    exposing
        ( Route(..)
        , Msg
        , goto
        , fromLocation
        , routeToUrl
        , href
        , newUrl
        )

import Task
import Html exposing (Attribute)
import Html.Attributes as Attr
import Navigation exposing (Location)
import UrlParser as Url
    exposing
        ( (</>)
        , Parser
        , oneOf
        , parseHash
        , s
        , string
        , top
        )


type Route
    = NotFound
    | ObservationDetail String
    | ObservationList
    | ObservationNew


router : Parser (Route -> a) a
router =
    oneOf
        [ Url.map ObservationList top
        , Url.map ObservationNew (s "observations" </> (s "new"))
        , Url.map ObservationList (s "observations")
        , Url.map ObservationDetail (s "observations" </> Url.string)
        ]


fromLocation : Location -> Route
fromLocation location =
    if String.isEmpty location.hash then
        ObservationList
    else
        case (parseHash router location) of
            Nothing ->
                NotFound

            Just route ->
                route


routeToUrl : Route -> String
routeToUrl route =
    let
        pieces =
            case route of
                ObservationList ->
                    []

                ObservationNew ->
                    [ "observations/new" ]

                NotFound ->
                    [ "404" ]

                ObservationDetail id_ ->
                    [ "observations", id_ ]
    in
        "#/" ++ String.join "/" pieces


href : Route -> Attribute msg
href route =
    Attr.href (routeToUrl route)


newUrl : Route -> Cmd msg
newUrl route =
    Navigation.newUrl (routeToUrl route)


type alias Msg msg =
    Route -> msg


goto : Route -> Msg msg -> Cmd msg
goto route tagger =
    Task.perform tagger <| Task.succeed route
