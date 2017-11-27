module Sleep.List
    exposing
        ( Model
        , Msg(..)
        , ExternalMsg(..)
        , update
        , view
        , subscriptions
        , init
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Views.Nav exposing (nav)
import Css
import Router
import Store exposing (Store)
import Sleep.Types
    exposing
        ( PaginatedSleeps
        , fromSleepId
        , Sleep
        , sleepDuration
        )
import Utils
    exposing
        ( Pagination
        , toPaginationVars
        , (=>)
        )
import Date.Format as DateFormat
import Phoenix
import Views.Pagination exposing (viewPagination)
import Sleep.Channel as Channel exposing (ChannelState)


type alias Model =
    ()


init : Model
init =
    ()


type Msg
    = NoOp ()
    | Paginate Pagination
    | ChannelMsg ChannelState


type alias QueryStore =
    { websocketUrl : Maybe String
    , paginatedSleeps : PaginatedSleeps
    }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store
    , paginatedSleeps = Store.getPaginatedSleeps store
    }


type ExternalMsg
    = None
    | SleepsReceived PaginatedSleeps


update : Msg -> Model -> QueryStore -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model store =
    case msg of
        Paginate pagination ->
            let
                cmd =
                    toPaginationVars pagination
                        |> Channel.list
                        |> Phoenix.push
                            (Maybe.withDefault "" store.websocketUrl)
                        |> Cmd.map ChannelMsg
            in
                model ! [ cmd ] => None

        ChannelMsg channelState ->
            case channelState of
                Channel.ListSucceeds result ->
                    case result of
                        Ok data ->
                            () ! [] => SleepsReceived data

                        Err err ->
                            let
                                message =
                                    "\n\n error decoding response from ->"
                                        ++ toString msg

                                x =
                                    Debug.log message err
                            in
                                model ! [] => None

                _ ->
                    model ! [] => None

        NoOp _ ->
            ( model, Cmd.none ) => None



-- VIEW


view : Model -> QueryStore -> Html Msg
view model { paginatedSleeps } =
    let
        { entries, pagination } =
            paginatedSleeps
    in
        Html.div [ Attr.id "sleep-list-view" ]
            [ nav
                (Just Router.SleepList)
                Router.SleepList
                Router.SleepNew
                "sleep"
            , viewTable entries
            , viewPagination pagination Paginate
            ]


viewTable : List Sleep -> Html Msg
viewTable sleeps =
    Html.div
        [ Attr.class "iw" ]
        [ Html.table
            [ Attr.class "ck", Attr.attribute "data-sort" "table" ]
            [ viewHeader
            , Html.tbody
                []
                (List.map viewSleepRow sleeps)
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
                [ Html.text "Start" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "End" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Duration" ]
            ]
        ]


viewSleepRow : Sleep -> Html Msg
viewSleepRow { id, start, end } =
    let
        viewFormattedTime time =
            Html.div
                []
                [ Html.div
                    []
                    [ Html.text <| DateFormat.format "%a %d/%b/%y" time ]
                , Html.div
                    []
                    [ Html.text <| DateFormat.format "%l:%M %p" time ]
                ]
    in
        Html.tr
            []
            [ Html.td []
                [ Html.a
                    [ Attr.class
                        "bpb fa fa-eye sleep-list-to-sleep-detail-link"
                    , Attr.attribute "aria-hidden" "true"
                    , styles [ Css.color Css.inherit ]
                    , Router.href <| Router.SleepDetail <| fromSleepId id
                    ]
                    []
                ]
            , Html.td
                []
                [ viewFormattedTime start ]
            , Html.td
                []
                [ viewFormattedTime end ]
            , Html.td
                []
                [ Html.text <| sleepDuration start end ]
            ]


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
