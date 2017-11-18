module Observation.List
    exposing
        ( Model
        , Msg(..)
        , ExternalMsg(..)
        , update
        , view
        , init
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Observation.Channel as Channel exposing (ChannelState)
import Observation.Types exposing (Observation, PaginatedObservations)
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
import SharedStyles exposing (..)
import AppStyles exposing (appNamespace)


type alias Model =
    ()


init : Model
init =
    ()


type Msg
    = NoOp
    | Paginate Pagination
    | ChannelMsg ChannelState


type alias QueryStore =
    { websocketUrl : Maybe String
    , paginatedObservations : PaginatedObservations
    }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store
    , paginatedObservations = Store.getPaginatedObservations store
    }


type ExternalMsg
    = None
    | ObservationsReceived PaginatedObservations


update : Msg -> Model -> QueryStore -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model { websocketUrl } =
    case msg of
        NoOp ->
            model ! [] => None

        Paginate pagination ->
            let
                cmd =
                    toPaginationParamsVars pagination
                        |> Channel.listObservations
                        |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                        |> Cmd.map ChannelMsg
            in
                model ! [ cmd ] => None

        ChannelMsg channelState ->
            case channelState of
                Channel.ListObservationsSucceeds result ->
                    case result of
                        Ok data ->
                            () ! [] => ObservationsReceived data

                        Err err ->
                            let
                                x =
                                    Debug.log "\n\n Channel.ListObservationsSucceeds err ->" err
                            in
                                model ! [] => None

                _ ->
                    model ! [] => None



-- VIEW


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


{ id, class, classList } =
    appNamespace


view : Model -> QueryStore -> Html Msg
view model { paginatedObservations } =
    let
        { entries, pagination } =
            paginatedObservations
    in
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
                [ Attr.class "header"
                , class [ DisplayNoneMobileTableCell ]
                ]
                [ Html.text "Title" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.span
                    [ class [ ShowOnlyMobile ] ]
                    [ Html.text "Details" ]
                , Html.span
                    [ class [ ShowNoneMobile ] ]
                    [ Html.text "Comment" ]
                ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Created On" ]
            ]
        ]


viewObservationRow : Observation -> Html Msg
viewObservationRow { id, comment, insertedAt, meta } =
    Html.tr
        []
        [ Html.td []
            [ Html.a
                [ Attr.class
                    "bpb fa fa-eye observation-list-to-observation-detail-link"
                , Attr.attribute "aria-hidden" "true"
                , styles [ Css.color Css.inherit ]
                , Router.href <| Router.ObservationDetail id
                ]
                []
            ]
        , Html.td
            [ class [ DisplayNoneMobileTableCell ] ]
            [ Html.text meta.title ]
        , Html.td
            []
            [ Html.h6
                [ class [ ShowOnlyMobile ] ]
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
