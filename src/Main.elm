module Main exposing (..)

import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import View
import Model exposing (Model, Msg(..))
import Store exposing (Flag)
import Page
import Observation.Detail.App as ObservationDetail
import Observation.New.App as ObservationNew
import Observation.Channel as ObservationChannel
import Navigation
import Router
import Meal.Channel as MealChannel
import Sleep.Channel as SleepChannel


subs : Model -> Sub Msg
subs model =
    let
        page =
            Page.getPage model.pageState

        subs =
            case page of
                Page.Blank ->
                    []

                Page.ObservationNew subModel ->
                    [ Sub.map ObservationNewMsg <|
                        ObservationNew.subscriptions subModel
                    ]

                Page.ObservationList subModel ->
                    []

                Page.ObservationDetail subModel ->
                    [ Sub.map ObservationDetailMsg <|
                        ObservationDetail.subscriptions subModel
                    ]

                _ ->
                    []
    in
        Sub.batch
            ([ phoenixSubscription model ] ++ subs)


socket : String -> Socket Msg
socket url =
    Socket.init url
        |> Socket.onClose (always WebsocketError)
        |> Socket.onNormalClose WebsocketError
        |> Socket.onAbnormalClose (always WebsocketError)
        |> Socket.reconnectTimer
            (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


phoenixSubscription : Model -> Sub Msg
phoenixSubscription ({ store, pageState } as model) =
    case Store.getWebsocketUrl store of
        Just url ->
            let
                page =
                    Page.getPage pageState

                status =
                    Store.getConnectionStatus store
            in
                Phoenix.connect (socket url) <|
                    Model.channel
                        :: case status of
                            Store.Connected ->
                                [ Channel.map
                                    ObservationChannelMsg
                                    ObservationChannel.channel
                                , Channel.map
                                    MealChannelMsg
                                    MealChannel.channel
                                , Channel.map
                                    SleepChannelMsg
                                    SleepChannel.channel
                                ]

                            _ ->
                                []

        Nothing ->
            Sub.none



---- PROGRAM ----


main : Program Flag Model Msg
main =
    Navigation.programWithFlags (Router.fromLocation >> SetRoute)
        { view = View.view
        , init = Model.init
        , update = Model.update
        , subscriptions = subs
        }
