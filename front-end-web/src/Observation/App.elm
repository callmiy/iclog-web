module Observation.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , queryStore
        , subscriptions
        )

import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation)
import Phoenix
import Store exposing (Store)
import Observation.Types exposing (Observation, Meta, CreateObservationWithMeta, CreateMeta, emptyMeta, emptyString)
import Observation.MetaAutocomplete as MetaAutocomplete
import Observation.Channel as Channel exposing (ChannelState)


subscriptions : Model -> Sub Msg
subscriptions ({ metaAutoComp } as model) =
    Sub.batch
        [ MetaAutocomplete.subscriptions metaAutoComp
            |> Sub.map MetaAutocompleteMsg
        ]


type alias Model =
    { form : Maybe (Form () CreateObservationWithMeta)
    , serverError : Maybe String
    , submitting : Bool
    , showingNewMetaForm : Bool
    , metaAutoComp : MetaAutocomplete.Model
    }


type Msg
    = NoOp
    | FormMsg Form.Msg
    | ChannelMsg ChannelState
    | Submit
    | Reset
    | ToggleForm
    | ToggleViewNewMeta
    | MetaAutocompleteMsg MetaAutocomplete.Msg


initialFields : List ( String, Field )
initialFields =
    []


emptyForm : Form () CreateObservationWithMeta
emptyForm =
    Form.initial initialFields <| validate init.showingNewMetaForm


init : Model
init =
    { form = Nothing
    , serverError = Nothing
    , submitting = False
    , showingNewMetaForm = False
    , metaAutoComp = MetaAutocomplete.init
    }



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ form, showingNewMetaForm, metaAutoComp } as model) { websocketUrl } =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Submit ->
            let
                newForm =
                    Form.update (validate showingNewMetaForm) Form.Submit <|
                        Maybe.withDefault emptyForm form

                newModel =
                    { model | form = Just newForm }
            in
                case ( showingNewMetaForm, Form.getOutput newForm, metaAutoComp.selection ) of
                    ( True, Just formValues, _ ) ->
                        let
                            cmd =
                                { comment = formValues.comment
                                , meta = formValues.meta
                                }
                                    |> Channel.createWithMeta
                                    |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                                    |> Cmd.map ChannelMsg
                        in
                            ( { newModel
                                | submitting = True
                              }
                            , cmd
                            )

                    ( False, Just { comment }, Just meta ) ->
                        let
                            cmd =
                                { comment = comment, metaId = meta.id }
                                    |> Channel.createNew
                                    |> Phoenix.push (Maybe.withDefault "" websocketUrl)
                                    |> Cmd.map ChannelMsg
                        in
                            ( { newModel
                                | submitting = True
                              }
                            , cmd
                            )

                    _ ->
                        newModel ! []

        Reset ->
            let
                newForm =
                    Form.update (validate showingNewMetaForm) (Form.Reset initialFields) <|
                        Maybe.withDefault emptyForm form
            in
                { model
                    | form = Just newForm
                    , serverError = Nothing
                    , metaAutoComp = MetaAutocomplete.init
                }
                    ! []

        FormMsg formMsg ->
            { model
                | form =
                    Just
                        (Form.update (validate showingNewMetaForm) formMsg <|
                            Maybe.withDefault emptyForm form
                        )
                , serverError = Nothing
            }
                ! []

        ToggleViewNewMeta ->
            { model | showingNewMetaForm = not model.showingNewMetaForm } ! []

        ToggleForm ->
            case form of
                Nothing ->
                    { model | form = Just emptyForm } ! []

                Just form_ ->
                    let
                        _ =
                            --reset form fields
                            Form.update (validate showingNewMetaForm) (Form.Reset initialFields) form_
                    in
                        { model
                            | form = Nothing
                            , showingNewMetaForm = False
                            , metaAutoComp = MetaAutocomplete.init
                            , submitting = False
                            , serverError = Nothing
                        }
                            ! []

        ChannelMsg channelState ->
            let
                unSubmit : Model -> Model
                unSubmit updatedModel =
                    { updatedModel | submitting = False }

                unknownServerError : Model
                unknownServerError =
                    { model | serverError = Just "Something went wrong!" }
                        |> unSubmit
            in
                case channelState of
                    Channel.CreateObservationSucceeds result ->
                        case result of
                            Ok data ->
                                let
                                    x =
                                        Debug.log "\n\nCreateObservationSucceeds" data
                                in
                                    ( unSubmit model, Cmd.none )

                            Err err ->
                                let
                                    x =
                                        Debug.log "NewWithMetaSucceeds decode error" err
                                in
                                    unknownServerError ! []

                    Channel.CreateObservationFails val ->
                        let
                            x =
                                Debug.log "NewWithMetaFails" val
                        in
                            unknownServerError ! []

                    _ ->
                        ( model, Cmd.none )

        MetaAutocompleteMsg subMsg ->
            case ( subMsg, metaAutoComp.editingAutocomp ) of
                ( MetaAutocomplete.SetAutoState _, False ) ->
                    --This will make sure we only trigger autocomplete when typing in the autocomplete input
                    model ! []

                _ ->
                    let
                        ( subModel, subCmd ) =
                            MetaAutocomplete.update subMsg model.metaAutoComp

                        cmd =
                            Cmd.map MetaAutocompleteMsg subCmd

                        newModel =
                            { model
                                | metaAutoComp =
                                    { subModel
                                        | websocketUrl = websocketUrl
                                    }
                            }
                    in
                        newModel ! [ cmd ]



-- FORM VALIDATION


nonEmpty : Int -> Validation () String
nonEmpty minLength =
    Validate.string
        |> Validate.andThen Validate.nonEmpty
        |> Validate.andThen (Validate.minLength minLength)


validate : Bool -> Validation () CreateObservationWithMeta
validate showingNewMetaForm =
    let
        validateMeta =
            Validate.map2 CreateMeta
                (Validate.field "title" validateTitle)
                (Validate.field "intro" (Validate.maybe Validate.string))

        validateTitle =
            if showingNewMetaForm == True then
                nonEmpty 3
            else
                Validate.succeed emptyString
    in
        Validate.map2 CreateObservationWithMeta
            (Validate.field "comment" (nonEmpty 3))
            (Validate.field "meta" validateMeta)
