module Observation.List.App
    exposing
        ( Model
        , Msg(..)
        , update
        , view
        , init
        , ExternalMsg(..)
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Observation.Channel as Channel exposing (PaginatedObservations, ChannelState)
import Observation.Types exposing (Observation)
import Date.Format as DateFormat
import Css
import Utils as GUtils exposing (viewPagination, Pagination, (=>), toPaginationParamsVars)
import Store exposing (Store)
import Phoenix


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


type alias Model =
    ()


init : Model
init =
    ()


type Msg
    = NoOp
    | Paginate Pagination
    | ChannelMsg ChannelState


type ExternalMsg
    = None
    | NewObservations PaginatedObservations


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


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
                            model ! [] => (NewObservations data)

                        Err err ->
                            let
                                x =
                                    Debug.log "\n\n Channel.ListObservationsSucceeds err ->" err
                            in
                                model ! [] => None

                _ ->
                    model ! [] => None


view : PaginatedObservations -> Model -> Html Msg
view { entries, pagination } model =
    Html.div
        []
        [ viewTable entries
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
                [ Html.input
                    [ Attr.class "bpa"
                    , Attr.id "selectAll"
                    , Attr.type_ "checkbox"
                    ]
                    []
                ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Title" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Comment" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Created On" ]
            ]
        ]


viewObservationRow : Observation -> Html Msg
viewObservationRow { comment, insertedAt, meta } =
    Html.tr
        [ styles [ Css.cursor Css.pointer ] ]
        [ Html.td []
            [ Html.input
                [ Attr.class "bpb", Attr.type_ "checkbox" ]
                []
            ]
        , Html.td []
            [ Html.div
                []
                [ Html.text meta.title ]
            ]
        , Html.td
            []
            [ Html.div
                []
                [ Html.text comment ]
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
