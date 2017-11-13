module Observation.Detail.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , subscriptions
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Observation.Navigation as Navigation
import Css
import Observation.Types exposing (Observation)
import Observation.Channel as Channel exposing (ChannelState)
import Store exposing (Store)
import Phoenix
import Date.Format as DateFormat


type alias Model =
    { observation : Maybe Observation }


init : String -> QueryStore -> ( Model, Cmd Msg )
init id_ { websocketUrl } =
    let
        cmd =
            Channel.getObservation id_
                |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                |> Cmd.map ChannelMsg
    in
        { observation = Nothing } ! [ cmd ]


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


type Msg
    = NoOp
    | ChannelMsg ChannelState


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg model store =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChannelMsg channelState ->
            case channelState of
                Channel.GetObservationSucceeds result ->
                    case result of
                        Ok data ->
                            { observation = Just data } ! []

                        Err err ->
                            let
                                x =
                                    Debug.log "\n\n Channel.GetObservationSucceeds err ->" err
                            in
                                model ! []

                _ ->
                    model ! []



-- VIEW


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> Html Msg
view ({ observation } as model) =
    let
        mainView =
            case observation of
                Nothing ->
                    Html.text ""

                Just observation_ ->
                    viewTab observation_
    in
        Html.div
            [ Attr.id "observation-list-detail" ]
            [ Navigation.nav Nothing
            , mainView
            ]


viewTab : Observation -> Html Msg
viewTab ({ meta, comment, insertedAt } as observation) =
    Html.div
        [ Attr.class "card" ]
        [ Html.div
            [ Attr.class "card-body" ]
            [ Html.h4
                [ Attr.class "card-title"
                , styles [ Css.color Css.inherit ]
                ]
                [ Html.text meta.title ]
            , Html.p
                [ Attr.class "card-text" ]
                [ Html.text comment ]
            , Html.a
                [ Attr.class "card-link fa fa-pencil-square-o"
                , Attr.href "#"
                ]
                []
            ]
        , Html.div
            [ Attr.class "card-footer text-muted" ]
            [ Html.text <| DateFormat.format "%a %d/%b/%y" insertedAt ]
        ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
