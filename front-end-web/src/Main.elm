module Main exposing (..)

import Html
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import Observation.Model as Observation
import View
import Model exposing (Model, Msg)
import Store exposing (Flag)


subs : Model -> Sub Msg
subs model =
    Sub.batch [ phoenixSubscription model ]


socket : String -> Socket Msg
socket url =
    Socket.init url
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


phoenixSubscription : Model -> Sub Msg
phoenixSubscription ({ store } as model) =
    case Store.getWebsocketUrl store of
        Just url ->
            Phoenix.connect (socket url) <|
                [ Channel.map
                    (Model.ObservationMsg << Observation.ChannelMsg)
                    Observation.channel
                ]

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
