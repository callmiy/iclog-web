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


type alias Model =
    { store : Store
    , pageState : PageState
    }


init : Flag -> ( Model, Cmd Msg )
init flag =
    let
        store =
            Store.create flag

        ( childModel, cmd ) =
            store
                |> ObservationList.queryStore
                |> ObservationList.init
    in
        { store = store
        , pageState = Loaded (Page.ObservationList childModel)
        }
            ! [ Cmd.map ObservationListMsg cmd ]



---- UPDATE ----


type Msg
    = NoOp
    | ObservationDetailMsg ObservationDetail.Msg
    | ObservationListMsg ObservationList.Msg
    | ObservationNewMsg ObservationNew.Msg
    | RouteMsg Route
    | ObservationChannelMsg ChannelState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pageState, store } as model) =
    case ( msg, Page.getPage pageState ) of
        ( ObservationListMsg (ObservationList.RouteMsg route), _ ) ->
            updateRoute model route

        ( ObservationNewMsg (ObservationNew.RouteMsg route), _ ) ->
            updateRoute model route

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


updateRoute : Model -> Route -> ( Model, Cmd Msg )
updateRoute ({ store } as model) route =
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
