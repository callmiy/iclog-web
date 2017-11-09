module Observation.App
    exposing
        ( Model
        , Msg(..)
        , App(..)
        , Showing(..)
        , init
        , update
        , queryStore
        , subscriptions
        , channels
        )

import Store exposing (Store)
import Observation.New.App as New
import Observation.Channel as ObservationChannel exposing (ChannelState, PaginatedObservations)
import Observation.List.App as ListApp
import Phoenix.Channel as Channel exposing (Channel)
import Utils as GUtils exposing (defaultPagination)
import Observation.Types exposing (Observation)


subscriptions : Model -> Sub Msg
subscriptions ({ showing } as model) =
    Sub.batch
        [ case showing of
            ShowNew subModel ->
                New.subscriptions subModel |> Sub.map NewMsg

            ShowList _ ->
                Sub.none
        ]


channels : Channel Msg
channels =
    Channel.map ChannelMsg ObservationChannel.channel


type Showing
    = ShowNew New.Model
    | ShowList ListApp.Model


type App
    = NewApp
    | ListApp_


type alias Model =
    { showing : Showing
    , observations : PaginatedObservations
    }


type Msg
    = NoOp
    | ChannelMsg ChannelState
    | NewMsg New.Msg
    | ListMsg ListApp.Msg
    | ChangeDisplay App


init : ( Model, Cmd Msg )
init =
    { showing = ShowList ListApp.init
    , observations =
        { entries = []
        , pagination = defaultPagination
        }
    }
        ! []



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ showing } as model) store =
    case ( msg, showing ) of
        ( ChannelMsg (ObservationChannel.Joined response), _ ) ->
            case response of
                Ok data ->
                    { model | observations = data } ! []

                Err err ->
                    let
                        x =
                            Debug.log "\n\nObservationChannel.Joined error " err
                    in
                        model ! []

        ( ChannelMsg _, _ ) ->
            model ! []

        ( NewMsg subMsg, ShowNew subModel ) ->
            let
                ( ( newSubModel, cmd ), externalMsg ) =
                    New.update subMsg subModel store

                updatedModel =
                    case externalMsg of
                        New.ObservationCreated data ->
                            let
                                model_ =
                                    insertObservation data model
                            in
                                { model_
                                    | showing = ShowNew newSubModel
                                }

                        New.None ->
                            { model | showing = ShowNew newSubModel }
            in
                updatedModel ! [ Cmd.map NewMsg cmd ]

        ( ListMsg subMsg, ShowList subModel ) ->
            let
                ( newSubModel, cmd ) =
                    ListApp.update subMsg subModel
            in
                { model
                    | showing = ShowList newSubModel
                }
                    ! [ Cmd.map ListMsg cmd ]

        ( ChangeDisplay NewApp, _ ) ->
            { model
                | showing = ShowNew New.init
            }
                ! []

        ( ChangeDisplay ListApp_, _ ) ->
            { model
                | showing = ShowList ListApp.init
            }
                ! []

        ( NewMsg _, ShowList _ ) ->
            model ! []

        ( ListMsg _, ShowNew _ ) ->
            model ! []

        ( NoOp, _ ) ->
            ( model, Cmd.none )


insertObservation : Observation -> Model -> Model
insertObservation observation ({ observations } as model) =
    { model
        | observations =
            { observations
                | entries =
                    List.take
                        10
                        (observation :: observations.entries)
            }
    }
