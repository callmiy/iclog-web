module Observation.New.App
    exposing
        ( Model
        , Msg(..)
        , ExternalMsg(..)
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
    }


type Msg
    = NoOp
    | FormMsg Form.Msg
    | ChannelMsg ChannelState
    | Submit
    | Reset
    | ToggleViewNewMeta
    | MetaAutocompleteMsg MetaAutocomplete.Msg


type ExternalMsg
    = None
    | ObservationCreated Observation


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
    }



-- UPDATE


type alias QueryStore =
    { websocketUrl : Maybe String }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store }


update : Msg -> Model -> QueryStore -> ( ( Model, Cmd Msg ), ExternalMsg )
update msg ({ form, showingNewMetaForm, metaAutoComp } as model) { websocketUrl } =
    case msg of
        NoOp ->
            ( model, Cmd.none ) => None

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
                                => None

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
                                => None

                    _ ->
                        newModel ! [] => None

        Reset ->
            { model
                | form =
                    Form.update
                        (validate showingNewMetaForm)
                        (Form.Reset initialFields)
                        form
                , serverError = Nothing
                , metaAutoComp = MetaAutocomplete.init
            }
                => Cmd.none
                => None

        FormMsg formMsg ->
            { model
                | form =
                    (Form.update (validate showingNewMetaForm) formMsg form)
                , serverError = Nothing
            }
                => Cmd.none
                => None

        ToggleViewNewMeta ->
            { model | showingNewMetaForm = not model.showingNewMetaForm }
                => Cmd.none
                => None

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
                                ( unSubmit model, Cmd.none ) => ObservationCreated data

                            Err err ->
                                let
                                    x =
                                        Debug.log "NewWithMetaSucceeds decode error" err
                                in
                                    unknownServerError ! [] => None

                    Channel.CreateObservationFails val ->
                        let
                            x =
                                Debug.log "NewWithMetaFails" val
                        in
                            unknownServerError ! [] => None

                    _ ->
                        ( model, Cmd.none ) => None

        MetaAutocompleteMsg subMsg ->
            case ( subMsg, metaAutoComp.editingAutocomp ) of
                ( MetaAutocomplete.SetAutoState _, False ) ->
                    --This will make sure we only trigger autocomplete when typing in the autocomplete input
                    model ! [] => None

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
                        newModel ! [ cmd ] => None



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
        Html.form
            [ onSubmit Submit
            , Attr.novalidate True
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
                    ]
                    Nothing
                    FormMsg
                ]
            , formBtns label_ disableSubmitBtn disableResetBtn
            ]


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
                    , styles [ Css.cursor Css.pointer ]
                    , onClick ToggleViewNewMeta
                    ]
                    [ Html.span [ Attr.class "fa fa-plus-square" ] [] ]
                ]
             ]
                ++ menus
                ++ [ FormUtils.textualError error ]
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
                ]
                Nothing
                FormMsg
            , FormUtils.formGrp
                Input.textArea
                introField
                [ Attr.placeholder "Intro"
                , Attr.value (Maybe.withDefault "" introField.value)
                ]
                Nothing
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
