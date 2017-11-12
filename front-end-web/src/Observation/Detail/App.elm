module Observation.Detail.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , subscriptions
        )

import Html exposing (Html)


type alias Model =
    ()


init : String -> ( Model, Cmd Msg )
init id_ =
    () ! []


type Msg
    = NoOp


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    Html.div
        []
        [ Html.text "detail view" ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
