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
import Observation.Channel as ObservationChannel
import Navigation exposing (Location)
import Utils exposing ((=>), decodeErrorMsg)
import Meal.Detail.App as MealDetail
import Meal.List as MealList
import Meal.New as MealNew
import Meal.Channel as MealChannel


type alias Model =
    { store : Store
    , pageState : PageState
    , showingMobileNav : Bool
    , route : Route
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
            , showingMobileNav = False
            , route = route
            }
            route



---- UPDATE ----


type Msg
    = NoOp
    | ObservationDetailMsg ObservationDetail.Msg
    | ObservationListMsg ObservationList.Msg
    | ObservationNewMsg ObservationNew.Msg
    | MealDetailMsg MealDetail.Msg
    | MealListMsg MealList.Msg
    | MealNewMsg MealNew.Msg
    | RouteMsg Route
    | ObservationChannelMsg ObservationChannel.ChannelState
    | SetRoute Route
    | MealChannelMsg MealChannel.ChannelState
    | ToggleShowingMobileNav


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pageState, store } as model) =
    case ( msg, Page.getPage pageState ) of
        ( SetRoute route, _ ) ->
            setRoute
                { model
                    | showingMobileNav = False
                    , route = route
                }
                route

        ( ObservationNewMsg subMsg, Page.ObservationNew subModel ) ->
            let
                ( ( newModel, cmd_ ), externalMsg ) =
                    store
                        |> ObservationNew.queryStore
                        |> ObservationNew.update subMsg subModel

                model_ =
                    { model
                        | pageState =
                            Page.Loaded <|
                                Page.ObservationNew newModel
                    }

                cmd =
                    Cmd.map ObservationNewMsg cmd_
            in
                case externalMsg of
                    ObservationNew.None ->
                        model_ => cmd

                    ObservationNew.ObservationCreated observation ->
                        { model_
                            | store =
                                Store.addObservation
                                    observation
                                    store
                        }
                            ! [ cmd ]

        ( ObservationListMsg subMsg, Page.ObservationList subModel ) ->
            let
                ( ( newSubModel, cmd_ ), externalMsg ) =
                    ObservationList.queryStore store
                        |> ObservationList.update subMsg subModel

                cmd =
                    Cmd.map ObservationListMsg cmd_
            in
                case externalMsg of
                    ObservationList.ObservationsReceived observations ->
                        { model
                            | pageState =
                                Page.Loaded <|
                                    Page.ObservationList newSubModel
                            , store =
                                Store.updatePaginatedObservations
                                    observations
                                    store
                        }
                            ! [ cmd ]

                    ObservationList.None ->
                        model ! [ cmd ]

        ( ObservationDetailMsg subMsg, Page.ObservationDetail subModel ) ->
            updateObservationDetail subMsg model subModel

        ( ObservationChannelMsg (ObservationChannel.Joined result), _ ) ->
            case result of
                Ok data ->
                    { model
                        | store = Store.updatePaginatedObservations data store
                    }
                        ! []

                Err err ->
                    let
                        x =
                            Debug.log (decodeErrorMsg msg) err
                    in
                        model ! []

        ( MealChannelMsg (MealChannel.Joined result), _ ) ->
            case result of
                Ok data ->
                    { model
                        | store = Store.updatePaginatedMeals data store
                    }
                        ! []

                Err err ->
                    let
                        x =
                            Debug.log (decodeErrorMsg msg) err
                    in
                        model ! []

        ( MealChannelMsg (MealChannel.MealCreated result), _ ) ->
            case result of
                Ok data ->
                    { model
                        | store = Store.addMeal data store
                    }
                        ! []

                Err err ->
                    let
                        x =
                            Debug.log (decodeErrorMsg msg) err
                    in
                        model ! []

        ( MealChannelMsg (MealChannel.MealUpdated result), _ ) ->
            case result of
                Ok data ->
                    { model
                        | store = Store.updateMeal data store
                    }
                        ! []

                Err err ->
                    let
                        x =
                            Debug.log (decodeErrorMsg msg) err
                    in
                        model ! []

        ( MealListMsg subMsg, Page.MealList subModel ) ->
            let
                ( ( newSubModel, cmd_ ), externalMsg ) =
                    MealList.queryStore store
                        |> MealList.update subMsg subModel

                cmd =
                    Cmd.map MealListMsg cmd_
            in
                case externalMsg of
                    MealList.MealsReceived meals ->
                        { model
                            | pageState =
                                Page.Loaded <|
                                    Page.MealList newSubModel
                            , store =
                                Store.updatePaginatedMeals
                                    meals
                                    store
                        }
                            ! [ cmd ]

                    MealList.None ->
                        model ! [ cmd ]

        ( MealNewMsg subMsg, Page.MealNew subModel ) ->
            let
                ( newSubModel, cmd ) =
                    MealNew.queryStore store
                        |> MealNew.update subMsg subModel
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.MealNew newSubModel
                }
                    ! [ Cmd.map MealNewMsg cmd ]

        ( MealDetailMsg subMsg, Page.MealDetail subModel ) ->
            let
                ( newSubModel, cmd ) =
                    MealDetail.queryStore store
                        |> MealDetail.update subMsg subModel
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.MealDetail newSubModel
                }
                    ! [ Cmd.map MealDetailMsg cmd ]

        ( ToggleShowingMobileNav, _ ) ->
            { model | showingMobileNav = not model.showingMobileNav } ! []

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
                    ObservationDetail.queryStore store
                        |> ObservationDetail.init id_
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.ObservationDetail subModel
                }
                    ! [ Cmd.map ObservationDetailMsg cmd ]

        Router.ObservationNew ->
            let
                subModel =
                    ObservationNew.init
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.ObservationNew subModel
                }
                    ! []

        Router.ObservationList ->
            { model
                | pageState =
                    Page.Loaded <|
                        Page.ObservationList ObservationList.init
            }
                ! []

        Router.MealDetail id_ ->
            let
                ( subModel, cmd ) =
                    MealDetail.queryStore store
                        |> MealDetail.init id_
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.MealDetail subModel
                }
                    ! [ Cmd.map MealDetailMsg cmd ]

        Router.MealList ->
            { model
                | pageState =
                    Page.Loaded <|
                        Page.MealList MealList.init
            }
                ! []

        Router.MealNew ->
            let
                ( subModel, cmd ) =
                    MealNew.init
            in
                { model
                    | pageState =
                        Page.Loaded <|
                            Page.MealNew subModel
                }
                    ! [ Cmd.map MealNewMsg cmd ]


updateObservationList :
    ObservationList.Msg
    -> Model
    -> ObservationList.Model
    -> ( Model, Cmd Msg )
updateObservationList subMsg ({ store } as model) subModel =
    let
        ( ( newSubModel, cmd ), externalMsg ) =
            ObservationList.queryStore store
                |> ObservationList.update subMsg subModel
    in
        { model
            | pageState = Page.Loaded <| Page.ObservationList newSubModel
        }
            ! [ Cmd.map ObservationListMsg cmd ]


updateObservationDetail :
    ObservationDetail.Msg
    -> Model
    -> ObservationDetail.Model
    -> ( Model, Cmd Msg )
updateObservationDetail subMsg ({ store } as model) subModel =
    let
        ( ( newSubModel, cmd_ ), externalMsg ) =
            ObservationDetail.queryStore store
                |> ObservationDetail.update subMsg subModel

        cmd =
            Cmd.map ObservationDetailMsg cmd_

        model_ =
            { model
                | pageState = Page.Loaded <| Page.ObservationDetail newSubModel
            }
    in
        case externalMsg of
            ObservationDetail.None ->
                model_ ! [ cmd ]

            ObservationDetail.ObservationUpdated observation ->
                { model_
                    | store =
                        Store.updateObservation
                            observation
                            store
                }
                    ! [ cmd ]
