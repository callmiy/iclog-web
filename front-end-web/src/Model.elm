module Model
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        )

import Observation.Model as Observation
import Page exposing (Page, PageState(..))
import Store exposing (Flag, Store)


type alias Model =
    { store : Store
    , pageState : PageState
    }


init : Flag -> ( Model, Cmd Msg )
init flag =
    { store = Store.create flag
    , pageState = Loaded (Page.Observation Observation.init)
    }
        ! []



---- UPDATE ----


type Msg
    = NoOp
    | ObservationMsg Observation.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg ({ pageState, store } as model) =
    case ( msg, Page.getPage pageState ) of
        ( ObservationMsg subMsg, Page.Observation subModel ) ->
            let
                ( newModel, cmd ) =
                    store
                        |> Observation.queryStore
                        |> Observation.update subMsg subModel
            in
                { model | pageState = Page.Loaded <| Page.Observation newModel }
                    ! [ Cmd.map ObservationMsg cmd ]

        _ ->
            ( model, Cmd.none )
