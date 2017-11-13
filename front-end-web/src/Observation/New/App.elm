module Observation.New.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , queryStore
        , subscriptions
        , view
        )

import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation)
import Form.Input as Input exposing (Input)
import Phoenix
import Store exposing (Store)
import Observation.Types exposing (Observation, Meta, CreateObservationWithMeta, CreateMeta, emptyMeta, emptyString)
import Observation.New.MetaAutocomplete as MetaAutocomplete
import Observation.Channel as Channel exposing (ChannelState)
import Html.Events exposing (onClick, onSubmit)
import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Views.FormUtils as FormUtils
import Set
import Css
import SharedStyles exposing (..)
import Observation.Styles exposing (observationNamespace)
import Observation.Types exposing (CreateObservationWithMeta)
import Observation.Utils as LUtils exposing (stringGt)
import Utils as GUtils exposing ((=>))
import Router exposing (Route)
import Observation.Navigation as Navigation


subscriptions : Model -> Sub Msg
subscriptions ({ metaAutoComp } as model) =
    Sub.batch
        [ MetaAutocomplete.subscriptions metaAutoComp
            |> Sub.map MetaAutocompleteMsg
        ]


type alias Model =
    { form : Form () CreateObservationWithMeta
    , serverError : Maybe String
    , submitting : Bool
    , showingNewMetaForm : Bool
    , metaAutoComp : MetaAutocomplete.Model
    , newCreated : Maybe Observation
    }


type Msg
    = NoOp
    | FormMsg Form.Msg
    | ChannelMsg ChannelState
    | Submit
    | Reset
    | ToggleViewNewMeta
    | MetaAutocompleteMsg MetaAutocomplete.Msg


initialFields : List ( String, Field )
initialFields =
    []


init : Model
init =
    { form = Form.initial initialFields <| validate False
    , serverError = Nothing
    , submitting = False
    , showingNewMetaForm = False
    , metaAutoComp = MetaAutocomplete.init
    , newCreated = Nothing
    }



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ form, showingNewMetaForm, metaAutoComp } as model) ({ websocketUrl } as store) =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        Submit ->
            let
                newForm =
                    Form.update (validate showingNewMetaForm) Form.Submit form

                newModel =
                    { model | form = newForm }
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
            model |> reset |> resetNew => Cmd.none

        FormMsg formMsg ->
            { model
                | form =
                    (Form.update (validate showingNewMetaForm) formMsg form)
                , serverError = Nothing
            }
                |> resetNew
                => Cmd.none

        ToggleViewNewMeta ->
            { model | showingNewMetaForm = not model.showingNewMetaForm }
                |> resetNew
                => Cmd.none

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
                                model
                                    |> unSubmit
                                    |> reset
                                    |> updateNew data
                                    => Cmd.none

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
                        resetNew newModel ! [ cmd ]


reset : Model -> Model
reset model =
    { model
        | form =
            Form.update
                (validate model.showingNewMetaForm)
                (Form.Reset initialFields)
                model.form
        , serverError = Nothing
        , metaAutoComp = MetaAutocomplete.init
    }


resetNew : Model -> Model
resetNew model =
    { model | newCreated = Nothing }


updateNew : Observation -> Model -> Model
updateNew obs model =
    { model | newCreated = Just obs }



-- VIEW


{ id, class, classList } =
    observationNamespace


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> Html Msg
view ({ form, serverError, submitting, metaAutoComp } as model) =
    let
        commentField =
            Form.getFieldAsString "comment" form

        label_ =
            case submitting of
                True ->
                    "Submitting.."

                False ->
                    "Submit"

        formIsEmpty =
            Set.isEmpty <| Form.getChangedFields form

        showingQueryForm =
            (not model.showingNewMetaForm)

        styles_ =
            if model.showingNewMetaForm == True then
                [ Css.marginTop (Css.rem 2.5) ]
            else
                []

        queryEmpty =
            (not <| stringGt metaAutoComp.query 0)

        queryInvalid =
            showingQueryForm
                && ((not <| stringGt metaAutoComp.query 2)
                        || (metaAutoComp.selection == Nothing)
                   )

        disableSubmitBtn =
            formIsEmpty
                || queryInvalid
                || ([] /= Form.getErrors form)
                || (submitting == True)

        disableResetBtn =
            (queryEmpty && formIsEmpty)
                || (submitting == True)
    in
        Html.div
            []
            [ Navigation.nav Router.ObservationNew
            , viewNewInfo <| Maybe.andThen (\o -> Just o.id) model.newCreated
            , Html.form
                [ onSubmit Submit
                , Attr.novalidate True
                , Attr.id "new-observable-form"
                , styles styles_
                ]
                [ FormUtils.textualErrorBox serverError
                , viewMeta form model
                , Html.fieldset
                    []
                    [ FormUtils.formGrp
                        Input.textArea
                        commentField
                        [ Attr.placeholder "Comment"
                        , Attr.value (Maybe.withDefault "" commentField.value)
                        , Attr.name "new-observation-comment"
                        ]
                        { errorId = "new-observation-comment-error-id", errors = Nothing }
                        FormMsg
                    ]
                , formBtns label_ disableSubmitBtn disableResetBtn
                ]
            ]


viewNewInfo : Maybe String -> Html Msg
viewNewInfo maybeId =
    case maybeId of
        Nothing ->
            Html.text ""

        Just id_ ->
            Html.a
                [ Attr.id "new-observation-created-info"
                , Attr.class "new-observation-created-info alert alert-success"
                , Attr.attribute "role" "alert"
                , styles [ Css.display Css.block ]
                , Router.href <| Router.ObservationDetail id_
                ]
                [ Html.text "Success! Click here for further details." ]


viewMeta : Form () CreateObservationWithMeta -> Model -> Html Msg
viewMeta form_ ({ showingNewMetaForm } as model) =
    let
        viewing =
            if showingNewMetaForm == True then
                viewNewMeta form_
            else
                viewMetaSelect model
    in
        Html.div
            [ styles [ Css.marginTop (Css.rem 0.75) ] ]
            [ viewing ]


viewMetaSelect : Model -> Html Msg
viewMetaSelect ({ showingNewMetaForm, metaAutoComp } as model) =
    let
        isChanged =
            stringGt metaAutoComp.query 0

        nothingSelected =
            isChanged && (metaAutoComp.selection == Nothing)

        queryInvalid =
            isChanged && (not <| stringGt metaAutoComp.query 2)

        showingQuery =
            (not showingNewMetaForm) && isChanged

        ( isValid, isInvalid, error ) =
            case ( showingQuery, queryInvalid, nothingSelected ) of
                ( True, True, _ ) ->
                    ( False, True, Just "Type more than 3 chars to trigger autocomplete!" )

                ( True, False, True ) ->
                    ( False, True, Just "Select an option from autocomplete!" )

                ( True, False, False ) ->
                    ( True, False, Nothing )

                _ ->
                    ( False, False, Nothing )

        ( autoCompleteAttributes, menus_ ) =
            MetaAutocomplete.view model.metaAutoComp

        attributes =
            [ Attr.placeholder "Type to select title or click + to create"
            , Attr.classList
                [ ( "form-control", True )
                , ( "is-invalid", isInvalid )
                , ( "is-valid", isValid )
                ]
            , Attr.id "select-meta-input"
            ]
                ++ autoCompleteAttributes

        input =
            Html.map MetaAutocompleteMsg <| Html.input attributes []

        menus =
            List.map
                (\menu -> Html.map MetaAutocompleteMsg menu)
                menus_
    in
        Html.div
            [ Attr.class "meta-select" ]
            ([ Html.div
                [ Attr.class "blj input-group" ]
                [ input
                , Html.span
                    [ Attr.class "input-group-addon"
                    , Attr.id "reveal-new-meta-form-icon"
                    , styles [ Css.cursor Css.pointer ]
                    , onClick ToggleViewNewMeta
                    ]
                    [ Html.span [ Attr.class "fa fa-plus-square" ] [] ]
                ]
             ]
                ++ menus
                ++ [ FormUtils.textualError
                        { errors = error
                        , errorId = "select-meta-input-error-id"
                        }
                   ]
            )


viewNewMeta : Form () CreateObservationWithMeta -> Html Msg
viewNewMeta form_ =
    let
        titleField =
            Form.getFieldAsString "meta.title" form_

        introField =
            Form.getFieldAsString "meta.intro" form_
    in
        Html.div
            [ class [ NewMeta ] ]
            [ Html.div
                [ class [ NewMetaLegend ] ]
                [ Html.span
                    [ Attr.class "fa fa-minus-square"
                    , Attr.id "dismiss-new-meta-form-icon"
                    , class [ NewMetaDismiss ]
                    , onClick ToggleViewNewMeta
                    ]
                    [ Html.span
                        [ styles [ Css.marginLeft (Css.px 5) ] ]
                        [ Html.text "New Meta" ]
                    ]
                ]
            , FormUtils.formGrp
                Input.textInput
                titleField
                [ Attr.placeholder "Title"
                , Attr.value (Maybe.withDefault "" titleField.value)
                , Attr.name "new-observation-meta-title"
                , styles [ Css.marginTop (Css.rem 1.2) ]
                ]
                { errorId = "new-observation-meta-title-error-id", errors = Nothing }
                FormMsg
            , FormUtils.formGrp
                Input.textArea
                introField
                [ Attr.placeholder "Intro"
                , Attr.name "new-observation-meta-intro"
                , Attr.value (Maybe.withDefault "" introField.value)
                ]
                { errorId = "new-observation-meta-intro-error-id", errors = Nothing }
                FormMsg
            ]


formBtns : String -> Bool -> Bool -> Html Msg
formBtns label_ disableSubmitBtn disableResetBtn =
    Html.div
        [ styles [ Css.displayFlex ] ]
        [ Html.button
            [ styles [ Css.flex (Css.int 1) ]
            , Attr.class "btn btn-info"
            , Attr.type_ "submit"
            , Attr.disabled disableSubmitBtn
            , Attr.name "new-observation-submit-btn"
            ]
            [ Html.span
                [ Attr.class "fa fa-send"
                , styles
                    [ Css.display Css.inline
                    , Css.marginRight (Css.px 5)
                    ]
                ]
                []
            , Html.text label_
            ]
        , Html.button
            [ styles [ Css.marginLeft (Css.rem 4) ]
            , Attr.class "btn btn-outline-warning"
            , Attr.disabled disableResetBtn
            , Attr.type_ "button"
            , Attr.name "new-observation-reset-btn"
            , onClick Reset
            ]
            [ Html.text "Reset" ]
        ]



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
