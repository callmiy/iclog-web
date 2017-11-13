module Observation.List
    exposing
        ( Model
        , Msg(..)
        , update
        , view
        , init
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Observation.Channel as Channel exposing (PaginatedObservations, ChannelState)
import Observation.Types exposing (Observation)
import Date.Format as DateFormat
import Css
import Utils as GUtils
    exposing
        ( viewPagination
        , Pagination
        , (=>)
        , toPaginationParamsVars
        , defaultPaginationParamsVar
        , defaultPagination
        )
import Store exposing (Store)
import Phoenix
import Router exposing (Route)
import Observation.Navigation as Navigation


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


type alias Model =
    PaginatedObservations


init : QueryStore -> ( Model, Cmd Msg )
init { websocketUrl } =
    let
        cmd =
            defaultPaginationParamsVar
                |> Channel.listObservations
                |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                |> Cmd.map ChannelMsg
    in
        { entries = []
        , pagination = defaultPagination
        }
            ! [ cmd ]


type Msg
    = NoOp
    | Paginate Pagination
    | ChannelMsg ChannelState


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg model { websocketUrl } =
    case msg of
        NoOp ->
            model ! []

        Paginate pagination ->
            let
                cmd =
                    toPaginationParamsVars pagination
                        |> Channel.listObservations
                        |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                        |> Cmd.map ChannelMsg
            in
                model ! [ cmd ]

        ChannelMsg channelState ->
            case channelState of
                Channel.ListObservationsSucceeds result ->
                    case result of
                        Ok data ->
                            data ! []

                        Err err ->
                            let
                                x =
                                    Debug.log "\n\n Channel.ListObservationsSucceeds err ->" err
                            in
                                model ! []

                Channel.Joined response ->
                    case response of
                        Ok data ->
                            data ! []

                        Err err ->
                            let
                                x =
                                    Debug.log "\n\nObservationChannel.Joined error " err
                            in
                                model ! []

                _ ->
                    model ! []


view : Model -> Html Msg
view { entries, pagination } =
    Html.div
        [ Attr.id "observation-list-view" ]
        [ Navigation.nav <| Just Router.ObservationList
        , viewTable entries
        , viewPagination pagination Paginate
        ]


viewTable : List Observation -> Html Msg
viewTable observations =
    Html.div
        [ Attr.class "iw" ]
        [ Html.table
            [ Attr.class "ck", Attr.attribute "data-sort" "table" ]
            [ viewHeader
            , Html.tbody
                []
                (List.map viewObservationRow observations)
            ]
        ]


viewHeader : Html Msg
viewHeader =
    Html.thead
        []
        [ Html.tr
            []
            [ Html.th
                [ Attr.class "header headerSortDown" ]
                []
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Details" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Created On" ]
            ]
        ]


viewObservationRow : Observation -> Html Msg
viewObservationRow { id, comment, insertedAt, meta } =
    Html.tr
        [ styles [ Css.cursor Css.pointer ] ]
        [ Html.td []
            [ Html.a
                [ Attr.class "bpb fa fa-eye"
                , Attr.attribute "aria-hidden" "true"
                , styles [ Css.color Css.inherit ]
                , Router.href <| Router.ObservationDetail id
                ]
                []
            ]
        , Html.td
            []
            [ Html.h6
                []
                [ Html.text meta.title ]
            , Html.div
                []
                [ Html.text <| String.slice 0 120 comment ]
            ]
        , Html.td
            []
            [ Html.div
                []
                [ Html.div
                    []
                    [ Html.text <| DateFormat.format "%a %d/%b/%y" insertedAt ]
                , Html.div
                    []
                    [ Html.text <| DateFormat.format "%l:%M %p" insertedAt ]
                ]
            ]
        ]
