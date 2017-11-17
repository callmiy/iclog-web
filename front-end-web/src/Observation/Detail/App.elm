module Observation.Detail.App
    exposing
        ( Model
        , Msg(..)
        , init
        , update
        , view
        , subscriptions
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onSubmit)
import Observation.Navigation as Navigation
import Css
import Observation.Types exposing (Observation)
import Observation.Channel as Channel exposing (ChannelState)
import Store exposing (Store, TimeZoneOffset)
import Phoenix
import Date.Format as DateFormat
import Views.FormUtils as FormUtils
import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation, withCustomError)
import Form.Input as Input exposing (Input)
import Date exposing (Date)
import Utils as GUtils exposing ((=>), nonEmpty)
import Date.Format as DateFormat
import DateTimePicker
import DateTimePicker.Config as DateTimePickerConfig
    exposing
        ( DatePickerConfig
        , defaultDateTimePickerConfig
        , TimePickerConfig
        )
import Date.Extra.Duration as Duration


type alias Model =
    { observation : Maybe Observation
    , viewing : Viewing
    , form : Form String FormValue
    , serverError : Maybe String
    , submitting : Bool
    , selectedDate : Maybe Date
    , datePickerState : DateTimePicker.State
    , editSuccess : Bool
    }


initialFields : String -> List ( String, Field )
initialFields comment =
    [ ( "comment", Field.string comment )
    ]


type alias FormValue =
    { comment : String
    }


type Viewing
    = ViewingDetail
    | ViewingEdit


init : String -> QueryStore -> ( Model, Cmd Msg )
init id_ { websocketUrl } =
    let
        url =
            Maybe.withDefault "" websocketUrl

        cmd =
            Channel.getObservation id_
                |> Phoenix.push url
                |> Cmd.map ChannelMsg
    in
        { observation = Nothing
        , viewing = ViewingDetail
        , form = Form.initial (initialFields "") validate
        , serverError = Nothing
        , submitting = False
        , selectedDate = Nothing
        , datePickerState = DateTimePicker.initialState
        , editSuccess = False
        }
            ! [ cmd
              , DateTimePicker.initialCmd
                    DatePickerChanged
                    DateTimePicker.initialState
              ]


type alias QueryStore =
    { websocketUrl : Maybe String
    , tzOffset : TimeZoneOffset
    }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store
    , tzOffset = Store.getTimeZoneOffset store
    }


type Msg
    = NoOp
    | ChannelMsg ChannelState
    | ChangeView Viewing
    | FormMsg Form.Msg
    | DatePickerChanged DateTimePicker.State (Maybe Date)
    | ResetForm
    | SubmitForm Observation
    | DismissEditSuccessInfo


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg model store =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        ChannelMsg channelState ->
            case channelState of
                Channel.GetObservationSucceeds result ->
                    case result of
                        Ok observation_ ->
                            observationReceived observation_ model
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log
                                        "\n\n Channel.GetObservationSucceeds err ->"
                                        err
                            in
                                model ! []

                Channel.UpdateObservationSucceeds result ->
                    case result of
                        Ok observation_ ->
                            (observationReceived observation_ model
                                |> GUtils.unSubmit
                                |> changeView ViewingDetail
                                |> editSuccess
                            )
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log
                                        "\n\n Channel.UpdateObservationSucceeds err ->"
                                        err
                            in
                                (GUtils.unSubmit model
                                    |> GUtils.unknownServerError
                                )
                                    ! []

                _ ->
                    model ! []

        ChangeView viewing ->
            changeView viewing model
                ! []

        FormMsg formMsg ->
            { model
                | form =
                    Form.update validate formMsg model.form
                , serverError = Nothing
            }
                => Cmd.none

        DatePickerChanged datePickerState maybeDate ->
            { model
                | datePickerState = datePickerState
                , selectedDate = maybeDate
            }
                ! []

        ResetForm ->
            resetForm model ! []

        SubmitForm { id } ->
            let
                form_ =
                    Form.update validate Form.Submit model.form

                model_ =
                    { model
                        | form = form_
                    }
            in
                case commentFromForm form_ of
                    Just comment ->
                        let
                            cmd =
                                { comment = Just comment
                                , id = id
                                , insertedAt =
                                    Maybe.map
                                        (formatDateISOWithTimeZone store.tzOffset)
                                        model.selectedDate
                                }
                                    |> Channel.updateObservation
                                    |> Phoenix.push
                                        (Maybe.withDefault
                                            ""
                                            store.websocketUrl
                                        )
                                    |> Cmd.map ChannelMsg
                        in
                            { model_
                                | submitting = True
                            }
                                ! [ cmd ]

                    _ ->
                        model_ ! []

        DismissEditSuccessInfo ->
            { model | editSuccess = False } ! []


resetForm : Model -> Model
resetForm ({ observation, form } as model) =
    case observation of
        Just ({ comment, insertedAt } as observation_) ->
            { model
                | form =
                    Form.update
                        validate
                        (Form.Reset <| initialFields comment)
                        form
                , selectedDate = Just insertedAt
                , editSuccess = False
            }

        Nothing ->
            model


commentFromForm : Form String FormValue -> Maybe String
commentFromForm form_ =
    Form.getOutput form_
        |> Maybe.map .comment


observationReceived : Observation -> Model -> Model
observationReceived observation_ model =
    { model
        | observation = Just observation_
        , selectedDate = Just observation_.insertedAt
    }


changeView : Viewing -> Model -> Model
changeView viewing model =
    let
        model_ =
            case viewing of
                ViewingEdit ->
                    resetForm model

                _ ->
                    model
    in
        { model_
            | viewing = viewing
        }


editSuccess : Model -> Model
editSuccess model =
    { model | editSuccess = True }



-- VIEW


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


view : Model -> Html Msg
view ({ observation, viewing } as model) =
    let
        mainView =
            case observation of
                Nothing ->
                    Html.text ""

                Just observation_ ->
                    case viewing of
                        ViewingDetail ->
                            viewDetail observation_ model

                        ViewingEdit ->
                            viewEdit
                                observation_
                                model
    in
        Html.div
            [ Attr.id "observation-list-detail" ]
            [ Navigation.nav Nothing
            , mainView
            ]


viewDetail : Observation -> Model -> Html Msg
viewDetail ({ meta, comment, insertedAt } as observation) model =
    Html.div
        [ Attr.class "card" ]
        [ Html.div
            [ Attr.class "card-body" ]
            [ viewEditSuccessInfo model.editSuccess
            , Html.h4
                [ Attr.class "card-title"
                , styles [ Css.color Css.inherit ]
                ]
                [ Html.text meta.title ]
            , Html.p
                [ Attr.class "card-text" ]
                [ Html.text comment ]
            , Html.i
                [ Attr.class "card-link fa fa-pencil-square-o"
                , styles
                    [ Css.cursor Css.pointer
                    , Css.display Css.inline
                    ]
                , onClick <| ChangeView ViewingEdit
                , Attr.id "detail-observation-show-edit-display"
                ]
                []
            ]
        , Html.div
            [ Attr.class "card-footer text-muted" ]
            [ Html.text <| formatDateForForm insertedAt ]
        ]


viewEditSuccessInfo : Bool -> Html Msg
viewEditSuccessInfo success =
    case success of
        False ->
            Html.text ""

        True ->
            Html.div
                [ Attr.id "edit-observation-success-info"
                , Attr.class
                    "edit-observation-success-info alert alert-success"
                , Attr.attribute "role" "alert"
                , styles [ Css.color (Css.rgb 0 0 0) ]
                ]
                [ Html.text "Update success!"
                , Html.button
                    [ Attr.type_ "button"
                    , Attr.class "close"
                    , onClick DismissEditSuccessInfo
                    , Attr.attribute "aria-label" "Close"
                    ]
                    [ Html.span
                        [ Attr.attribute "aria-hidden" "true" ]
                        [ Html.text "×" ]
                    ]
                ]


viewEdit : Observation -> Model -> Html Msg
viewEdit ({ meta, comment, insertedAt } as observation) ({ form } as model) =
    let
        ( commentControl, commentInvalid ) =
            formControlComment comment model

        ( insertedAtControl, insertedAtInvalid ) =
            formControlInsertedAt model

        label_ =
            case model.submitting of
                True ->
                    "Submitting..."

                False ->
                    "Submit"

        commentChanged =
            case commentFromForm form of
                Nothing ->
                    True

                Just comment_ ->
                    comment /= comment_

        insertedAtChanged =
            Maybe.map formatDateForForm model.selectedDate
                /= (Just <| formatDateForForm insertedAt)

        disableSubmitBtn =
            insertedAtInvalid
                || commentInvalid
                || ([] /= Form.getErrors form)
                || (model.submitting == True)
                || (commentChanged == False && insertedAtChanged == False)

        disableResetBtn =
            (model.submitting == True)
                || (commentChanged == False && insertedAtChanged == False)
    in
        Html.div
            [ Attr.class "row" ]
            [ Html.div
                [ Attr.class
                    "col-12 col-sm-10 offset-sm-1 col-md-8 offset-md-2"
                ]
                [ Html.div
                    [ Attr.class "card" ]
                    [ Html.form
                        [ Attr.class "card-body edit-observable-form"
                        , Attr.novalidate True
                        , Attr.id "edit-observable-form"
                        , onSubmit <| SubmitForm observation
                        ]
                        [ Html.div
                            [ Attr.class "edit-observable-form-controls"
                            , Attr.id "edit-observable-form-controls"
                            , styles [ Css.marginBottom (Css.rem 1) ]
                            ]
                            [ commentControl
                            , insertedAtControl
                            ]
                        , FormUtils.formBtns
                            [ Attr.disabled disableSubmitBtn
                            , Attr.name "edit-observation-submit-btn"
                            ]
                            [ Attr.disabled disableResetBtn
                            , Attr.name "edit-observation-reset-btn"
                            ]
                            label_
                            ResetForm
                        ]
                    , Html.div
                        [ Attr.class "card-footer " ]
                        [ Html.i
                            [ Attr.class "card-link fa fa-eye"
                            , styles [ Css.cursor Css.pointer ]
                            , onClick <| ChangeView ViewingDetail
                            , styles [ Css.display Css.inline ]
                            , Attr.id "detail-observation-show-detail-display"
                            ]
                            []
                        ]
                    ]
                ]
            ]


formControlComment : String -> Model -> ( Html Msg, Bool )
formControlComment comment { form } =
    let
        commentField =
            Form.getFieldAsString "comment" form

        ( isValid, isInvalid ) =
            FormUtils.controlValidityState commentField

        commentFieldValue =
            Maybe.withDefault
                comment
                commentField.value
    in
        (FormUtils.formGrp
            Input.textArea
            commentField
            [ Attr.placeholder "Comment"
            , Attr.name "edit-observation-comment"
            , Attr.value commentFieldValue
            , Attr.class "autoExpand"
            ]
            { errorId = "edit-observation-comment-error-id"
            , errors = Nothing
            }
            FormMsg
        )
            => isInvalid


formControlInsertedAt : Model -> ( Html Msg, Bool )
formControlInsertedAt model =
    let
        ( isValid, isInvalid, error ) =
            case model.selectedDate of
                Nothing ->
                    ( False
                    , True
                    , Just "Select a date from the datepicker."
                    )

                Just _ ->
                    ( True, False, Nothing )

        dateInput =
            DateTimePicker.dateTimePickerWithConfig
                config
                [ Attr.classList
                    [ ( "form-control", True )
                    , ( "is-invalid", isInvalid )
                    , ( "is-valid", isValid )
                    ]
                , Attr.id "edit-observation-inserted-at"
                , Attr.name "edit-observation-inserted-at"
                ]
                model.datePickerState
                model.selectedDate

        config : DateTimePickerConfig.Config (DatePickerConfig TimePickerConfig) Msg
        config =
            let
                defaultDateTimeConfig =
                    defaultDateTimePickerConfig DatePickerChanged

                i18n =
                    defaultDateTimeConfig.i18n

                inputFormat =
                    i18n.inputFormat

                i18n_ =
                    { i18n
                        | inputFormat =
                            { inputFormat
                                | inputFormatter = formatDateForForm
                            }
                    }
            in
                { defaultDateTimeConfig
                    | timePickerType = DateTimePickerConfig.Digital
                    , i18n = i18n_
                }
    in
        Html.div
            [ Attr.id "edit-observation-inserted-at-input-grpup" ]
            [ dateInput
            , FormUtils.textualError
                { errors = error
                , errorId = "edit-observation-inserted-at-error-id"
                }
            ]
            => isInvalid


validate : Validation String FormValue
validate =
    Validate.succeed FormValue
        |> Validate.andMap
            (Validate.field
                "comment"
                (nonEmpty 3 |> withCustomError "Comment must be at least 3 characters.")
            )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- UTILITIES


formatDateForForm : Date -> String
formatDateForForm date =
    DateFormat.format "%a %d/%b/%y %I:%M %p" date


formatDateISOWithTimeZone : TimeZoneOffset -> Date -> String
formatDateISOWithTimeZone tz date =
    Duration.add Duration.Minute (Store.toTimeZoneVal tz) date
        |> DateFormat.formatISO8601
