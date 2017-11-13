module Main exposing (..)

import Html
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import View
import Model exposing (Model, Msg)
import Store exposing (Flag)
import Page
import Observation.Detail.App as ObservationDetail
import Observation.New.App as ObservationNew
import Observation.Channel as ObservationChannel
import Navigation
import Router


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
                    [ Sub.map Model.ObservationNewMsg <| ObservationNew.subscriptions subModel ]

                Page.ObservationList subModel ->
                    []

                Page.ObservationDetail subModel ->
                    [ Sub.map Model.ObservationDetailMsg <| ObservationDetail.subscriptions subModel ]
    in
        Sub.batch
            ([ phoenixSubscription model ] ++ subs)


socket : String -> Socket Msg
socket url =
    Socket.init url
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


phoenixSubscription : Model -> Sub Msg
phoenixSubscription ({ store, pageState } as model) =
    case Store.getWebsocketUrl store of
        Just url ->
            let
                page =
                    Page.getPage pageState
            in
                Phoenix.connect (socket url)
                    [ Channel.map Model.ObservationChannelMsg ObservationChannel.channel ]

        Nothing ->
            Sub.none



---- PROGRAM ----


main : Program Flag Model Msg
main =
    Navigation.programWithFlags (Router.fromLocation >> Model.SetRoute)
        { view = View.view
        , init = Model.init
        , update = Model.update
        , subscriptions = subs
        }
