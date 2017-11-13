module Model
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        )

import Page exposing (Page, PageState(..))
import Store exposing (Flag, Store)
import Router exposing (Route)
import Observation.List as ObservationList
import Observation.Detail.App as ObservationDetail
import Observation.New.App as ObservationNew
import Observation.Channel as ObservationChannel exposing (ChannelState)
import Navigation exposing (Location)


type alias Model =
    { store : Store
    , pageState : PageState
    }


init : Flag -> Location -> ( Model, Cmd Msg )
init flag initialLocation =
    let
        route =
            Router.fromLocation initialLocation

        store =
            Store.create flag
    in
        setRoute
            { store = store
            , pageState = Loaded Page.Blank
            }
            route



---- UPDATE ----


type Msg
    = NoOp
    | ObservationDetailMsg ObservationDetail.Msg
    | ObservationListMsg ObservationList.Msg
    | ObservationNewMsg ObservationNew.Msg
    | RouteMsg Route
    | ObservationChannelMsg ChannelState
    | SetRoute Route


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pageState, store } as model) =
    case ( msg, Page.getPage pageState ) of
        ( SetRoute route, _ ) ->
            setRoute model route

        ( ObservationNewMsg subMsg, Page.ObservationNew subModel ) ->
            let
                ( newModel, cmd ) =
                    store
                        |> ObservationNew.queryStore
                        |> ObservationNew.update subMsg subModel
            in
                { model | pageState = Page.Loaded <| Page.ObservationNew newModel }
                    ! [ Cmd.map ObservationNewMsg cmd ]

        ( ObservationListMsg subMsg, Page.ObservationList subModel ) ->
            let
                ( newSubModel, cmd ) =
                    ObservationList.queryStore store
                        |> ObservationList.update subMsg subModel
            in
                { model
                    | pageState = Page.Loaded <| Page.ObservationList newSubModel
                }
                    ! [ Cmd.map ObservationListMsg cmd ]

        ( ObservationDetailMsg subMsg, Page.ObservationDetail subModel ) ->
            model ! []

        _ ->
            ( model, Cmd.none )


setRoute : Model -> Route -> ( Model, Cmd Msg )
setRoute ({ store } as model) route =
    case route of
        Router.NotFound ->
            model ! []

        Router.ObservationDetail id_ ->
            let
                ( subModel, cmd ) =
                    ObservationDetail.init id_
            in
                { model | pageState = Page.Loaded <| Page.ObservationDetail subModel }
                    ! [ Cmd.map ObservationDetailMsg cmd ]

        Router.ObservationNew ->
            let
                subModel =
                    ObservationNew.init
            in
                { model | pageState = Page.Loaded <| Page.ObservationNew subModel }
                    ! []

        Router.ObservationList ->
            let
                ( subModel, cmd ) =
                    store
                        |> ObservationList.queryStore
                        |> ObservationList.init
            in
                { model | pageState = Page.Loaded <| Page.ObservationList subModel }
                    ! [ Cmd.map ObservationListMsg cmd ]


updateObservationList :
    ObservationList.Msg
    -> Model
    -> ObservationList.Model
    -> ( Model, Cmd Msg )
updateObservationList subMsg ({ store } as model) subModel =
    let
        ( newSubModel, cmd ) =
            ObservationList.queryStore store
                |> ObservationList.update subMsg subModel
    in
        { model
            | pageState = Page.Loaded <| Page.ObservationList newSubModel
        }
            ! [ Cmd.map ObservationListMsg cmd ]
