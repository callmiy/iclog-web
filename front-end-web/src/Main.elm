module Main exposing (..)

import Html
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import Observation.App as Observation
import View
import Model exposing (Model, Msg)
import Store exposing (Flag)
import Page
import Observation.Channel as ObservationChannel


subs : Model -> Sub Msg
subs model =
    let
        page =
            Page.getPage model.pageState

        subs =
            case page of
                Page.Observation subModel ->
                    [ Sub.map Model.ObservationMsg <| Observation.subscriptions subModel ]
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

                channels =
                    case page of
                        Page.Observation _ ->
                            [ Channel.map Model.ObservationMsg Observation.channels ]
            in
                Phoenix.connect (socket url) channels

        Nothing ->
            Sub.none



---- PROGRAM ----


main : Program Flag Model Msg
main =
    Html.programWithFlags
        { view = View.view
        , init = Model.init
        , update = Model.update
        , subscriptions = subs
        }
