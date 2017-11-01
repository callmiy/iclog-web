module Main exposing (..)

import Html exposing (Html, text, div, img)
import Phoenix
import Phoenix.Socket as Socket exposing (Socket, AbnormalClose)
import Phoenix.Channel as Channel
import Channels.Observation as ObservationChan


---- MODEL ----


type alias Model =
    { store : Flag
    }


type alias Flag =
    { apiUrl : Maybe String
    , websocketUrl : Maybe String
    }


init : Flag -> ( Model, Cmd Msg )
init flag =
    ( { store = flag }, Cmd.none )



---- UPDATE ----


type Msg
    = NoOp
    | ObservationChanMsg ObservationChan.ChannelState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )



---- VIEW ----


view : Model -> Html Msg
view model =
    div []
        [ div [] [ text "Your Elm App is working!" ]
        ]



-- SUBSCRIPTION


subs : Model -> Sub Msg
subs model =
    Sub.batch [ phoenixSubscription model ]


socket : String -> Socket Msg
socket url =
    Socket.init url
        |> Socket.reconnectTimer (\backoffIteration -> (backoffIteration + 1) * 5000 |> toFloat)


phoenixSubscription : Model -> Sub Msg
phoenixSubscription ({ store } as model) =
    case store.websocketUrl of
        Just url ->
            Phoenix.connect (socket url) <|
                [ Channel.map ObservationChanMsg ObservationChan.channel ]

        Nothing ->
            Sub.none



---- PROGRAM ----


main : Program Flag Model Msg
main =
    Html.programWithFlags
        { view = view
        , init = init
        , update = update
        , subscriptions = subs
        }
