module Meal.List
    exposing
        ( Model
        , Msg
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
import Meal.Channel as Channel exposing (ChannelState)
import Meal.Types exposing (PaginatedMeals, fromMealId, Meal)
import Utils
    exposing
        ( Pagination
        , toPaginationParamsVars
        , (=>)
        )
import Date.Format as DateFormat
import Phoenix
import Views.Pagination exposing (viewPagination)


type alias Model =
    ()


type Msg
    = NoOp
    | Paginate Pagination
    | ChannelMsg ChannelState


type alias QueryStore =
    { websocketUrl : Maybe String
    , paginatedMeals : PaginatedMeals
    }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store
    , paginatedMeals = Store.getPaginatedMeals store
    }


type ExternalMsg
    = None
    | MealsReceived PaginatedMeals


update : Msg -> Model -> QueryStore -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg model { websocketUrl } =
    case msg of
        NoOp ->
            ( model, Cmd.none ) => None

        Paginate pagination ->
            let
                cmd =
                    toPaginationParamsVars pagination
                        |> Channel.list
                        |> Phoenix.push
                            (Maybe.withDefault "" websocketUrl)
                        |> Cmd.map ChannelMsg
            in
                model ! [ cmd ] => None

        ChannelMsg channelState ->
            case channelState of
                Channel.ListSucceeds result ->
                    case result of
                        Ok data ->
                            () ! [] => MealsReceived data

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



-- VIEW


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> QueryStore -> Html Msg
view model { paginatedMeals } =
    let
        { entries, pagination } =
            paginatedMeals
    in
        Html.div
            [ Attr.id "meal-list-view" ]
            [ nav
                (Just Router.MealList)
                Router.MealList
                Router.MealNew
                "meal"
            , viewTable entries
            , viewPagination pagination Paginate
            ]


viewTable : List Meal -> Html Msg
viewTable meals =
    Html.div
        [ Attr.class "iw" ]
        [ Html.table
            [ Attr.class "ck", Attr.attribute "data-sort" "table" ]
            [ viewHeader
            , Html.tbody
                []
                (List.map viewMealRow meals)
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
                [ Html.text "Meal" ]
            , Html.th
                [ Attr.class "header" ]
                [ Html.text "Time" ]
            ]
        ]


viewMealRow : Meal -> Html Msg
viewMealRow { id, meal, time } =
    Html.tr
        []
        [ Html.td []
            [ Html.a
                [ Attr.class
                    "bpb fa fa-eye meal-list-to-meal-detail-link"
                , Attr.attribute "aria-hidden" "true"
                , styles [ Css.color Css.inherit ]
                , Router.href <| Router.MealDetail <| fromMealId id
                ]
                []
            ]
        , Html.td
            []
            [ Html.text meal ]
        , Html.td
            []
            [ Html.div
                []
                [ Html.div
                    []
                    [ Html.text <| DateFormat.format "%a %d/%b/%y" time ]
                , Html.div
                    []
                    [ Html.text <| DateFormat.format "%l:%M %p" time ]
                ]
            ]
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none


init : Model
init =
    ()
