module Channels.Observation
    exposing
        ( channel
        , ChannelState(..)
        )

import Phoenix.Channel as Channel exposing (Channel)
import Json.Encode as Je exposing (Value)


type ChannelState
    = Joining
    | Joined Value
    | Leaving
    | Left
    | NewWithMeta Value
    | NewWithMetaSucceeds Value
    | NewWithMetaFails Value


channel : Channel ChannelState
channel =
    "observation:observation"
        |> Channel.init
        |> Channel.onRequestJoin Joining
        |> Channel.onJoin Joined
        |> Channel.onLeave (\_ -> Left)
        |> Channel.withDebug
