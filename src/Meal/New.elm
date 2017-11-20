module Meal.New
    exposing
        ( Model
        , Msg
        , update
        , view
        , subscriptions
        , init
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onSubmit, onClick)
import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Input as Input exposing (Input)
import Form.Validate as Validate exposing (Validation, withCustomError)
import Date exposing (Date)
import Utils as Utils
    exposing
        ( (=>)
        , nonEmpty
        , formatDateForForm
        , formatDateISOWithTimeZone
        , unSubmit
        , unknownServerError
        , decodeErrorMsg
        )
import DateTimePicker
import DateTimePicker.Config as DateTimePickerConfig
    exposing
        ( DatePickerConfig
        , defaultDateTimePickerConfig
        , TimePickerConfig
        )
import Meal.Types exposing (MealId, fromMealId)
import Store exposing (Store, TimeZoneOffset)
import Css
import Views.Nav exposing (nav)
import Router
import Views.FormUtils as FormUtils
import Task
import Dom
import Meal.Channel as Channel exposing (ChannelState)
import Phoenix
import Views.CreationSuccessAlert as CreationSuccessAlert


type alias Model =
    { form : Form String FormValue
    , serverError : Maybe String
    , submitting : Bool
    , creatingComment : Bool
    , selectedDate : Maybe Date
    , datePickerState : DateTimePicker.State
    , newMeal : Maybe MealId
    }


type alias FormValue =
    { meal : String
    , comment : CommentValue
    }


type alias CommentValue =
    { text : String }


initialFields : List ( String, Field )
initialFields =
    []


defaults : Model
defaults =
    { form = Form.initial initialFields <| validate False
    , serverError = Nothing
    , submitting = False
    , creatingComment = False
    , newMeal = Nothing
    , selectedDate = Nothing
    , datePickerState = DateTimePicker.initialState
    }


init : ( Model, Cmd Msg )
init =
    defaults
        ! [ focusEl "new-meal-input"
          , DateTimePicker.initialCmd
                DatePickerInitialMsg
                DateTimePicker.initialState
          , getDateNow
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
    = NoOp ()
    | FormMsg Form.Msg
    | DatePickerChanged DateTimePicker.State (Maybe Date)
    | DatePickerInitialMsg DateTimePicker.State (Maybe Date)
    | ResetForm
    | SubmitForm
    | Today Date
    | ToggleCommentForm
    | ChannelMsg ChannelState


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg ({ form } as model) store =
    case msg of
        Today today ->
            { model
                | selectedDate = Just today
            }
                ! []

        FormMsg formMsg ->
            revalidateForm formMsg model
                => Cmd.none

        DatePickerInitialMsg datePickerState _ ->
            { model
                | datePickerState = datePickerState
            }
                ! []

        DatePickerChanged datePickerState maybeDate ->
            { model
                | datePickerState = datePickerState
                , selectedDate = maybeDate
            }
                ! []

        ToggleCommentForm ->
            let
                newModel =
                    { model
                        | creatingComment = not model.creatingComment
                    }

                ( model_, cmd ) =
                    if model.creatingComment == True then
                        ( revalidateForm
                            (Form.Input
                                "comment.text"
                                Form.Textarea
                                (Field.String "")
                            )
                            newModel
                        , Cmd.none
                        )
                    else
                        ( newModel
                        , focusEl "new-meal-comment"
                        )
            in
                model_ ! [ cmd ]

        ResetForm ->
            resetForm model ! [ getDateNow ]

        SubmitForm ->
            let
                newForm =
                    Form.update
                        (validate model.creatingComment)
                        Form.Submit
                        form

                newModel =
                    { model | form = newForm }
            in
                case ( Form.getOutput newForm, model.selectedDate, store.websocketUrl ) of
                    ( Just { meal, comment }, Just date, Just websocketUrl ) ->
                        let
                            time =
                                formatDateISOWithTimeZone
                                    (Store.toTimeZoneVal
                                        store.tzOffset
                                    )
                                    date

                            params =
                                if model.creatingComment then
                                    { meal = meal
                                    , comment = Just comment
                                    , time = time
                                    }
                                else
                                    { meal = meal
                                    , comment = Nothing
                                    , time = time
                                    }

                            cmd =
                                Channel.create params
                                    |> Phoenix.push websocketUrl
                                    |> Cmd.map ChannelMsg
                        in
                            { newModel
                                | submitting = True
                            }
                                ! [ cmd ]

                    _ ->
                        model ! []

        ChannelMsg channelState ->
            case channelState of
                Channel.CreateSucceeds mealId_ ->
                    case mealId_ of
                        Ok mealId ->
                            { defaults | newMeal = Just mealId }
                                ! [ getDateNow ]

                        Err err ->
                            let
                                x =
                                    Debug.log (decodeErrorMsg msg) err
                            in
                                (unSubmit model
                                    |> unknownServerError
                                )
                                    ! []

                Channel.CreateFails val ->
                    let
                        model_ =
                            unSubmit model
                                |> unknownServerError

                        mesg =
                            "Channel.CreateFails with: "

                        x =
                            Debug.log ("\n\n ->" ++ mesg) val
                    in
                        model_ ! []

                _ ->
                    model ! []

        NoOp _ ->
            ( model, Cmd.none )


getDateNow : Cmd Msg
getDateNow =
    Task.perform Today Date.now


revalidateForm : Form.Msg -> Model -> Model
revalidateForm formMsg model =
    { model
        | form =
            Form.update
                (validate model.creatingComment)
                formMsg
                model.form
        , serverError = Nothing
    }


resetForm : Model -> Model
resetForm model =
    { model
        | form = Form.initial initialFields <| validate False
        , serverError = Nothing
        , submitting = False
        , creatingComment = False
        , newMeal = Nothing
        , datePickerState = DateTimePicker.initialState
    }


focusEl : String -> Cmd Msg
focusEl id_ =
    Task.attempt (Result.withDefault () >> NoOp) <|
        Dom.focus id_



-- VIEW


view : Model -> Html Msg
view ({ form, serverError, submitting } as model) =
    let
        ( mealControl, mealInvalid ) =
            formControlMeal model

        ( commentControl, commentInvalid ) =
            formControlComment model

        ( timeControl, timeInvalid ) =
            formControlTime model

        label_ =
            case submitting of
                True ->
                    "Submitting.."

                False ->
                    "Submit"

        disableSubmitBtn =
            timeInvalid
                || mealInvalid
                || commentInvalid
                || ([] /= Form.getErrors form)
                || (model.submitting == True)

        disableResetBtn =
            (model.submitting == True)
    in
        Html.div []
            [ nav
                (Just Router.MealNew)
                Router.MealList
                Router.MealNew
                "meal"
            , CreationSuccessAlert.view
                { id = (Maybe.map fromMealId model.newMeal)
                , route = Just Router.MealDetail
                , label = "meal"
                , dismissMsg = Nothing
                }
            , Html.div
                [ Attr.class "row" ]
                [ Html.div
                    [ Attr.class
                        "col-12 col-sm-10 offset-sm-1 col-md-8 offset-md-2"
                    ]
                    [ Html.div
                        [ Attr.class "card" ]
                        [ Html.form
                            [ Attr.class "card-body new-meal-form"
                            , Attr.novalidate True
                            , Attr.id "new-meal-form"
                            , onSubmit SubmitForm
                            ]
                            [ FormUtils.textualErrorBox model.serverError
                            , Html.div
                                [ Attr.class "new-meal-form-controls"
                                , Attr.id "new-meal-form-controls"
                                , styles [ Css.marginBottom (Css.rem 1) ]
                                ]
                                [ mealControl
                                , timeControl
                                , commentView
                                    commentControl
                                    model.creatingComment
                                ]
                            , FormUtils.formBtns
                                [ Attr.disabled disableSubmitBtn
                                , Attr.name "new-meal-submit-btn"
                                ]
                                [ Attr.disabled disableResetBtn
                                , Attr.name "new-meal-reset-btn"
                                ]
                                label_
                                ResetForm
                            ]
                        ]
                    ]
                ]
            ]


commentView : Html Msg -> Bool -> Html Msg
commentView commentControl creatingComment =
    let
        ( toggleClass, control, otherStyles ) =
            if creatingComment then
                ( "fa fa-minus"
                , commentControl
                , [ Css.paddingTop (Css.pct 5)
                  , Css.color (Css.rgb 216 41 41)
                  , Css.height (Css.pct 1)
                  ]
                )
            else
                ( "fa fa-comment", Html.text "", [] )

        styles_ =
            styles
                ([ Css.paddingLeft (Css.px 0)
                 , Css.width (Css.pct 10)
                 , Css.cursor Css.pointer
                 ]
                    ++ otherStyles
                )
    in
        Html.div
            [ styles
                [ Css.displayFlex
                , Css.marginTop (Css.px 10)
                ]
            ]
            [ Html.i
                [ Attr.class toggleClass
                , Attr.attribute "aria-hidden" "true"
                , onClick ToggleCommentForm
                , styles_
                ]
                []
            , Html.div
                [ styles [ Css.flex (Css.int 1) ] ]
                [ control ]
            ]


formControlComment : Model -> ( Html Msg, Bool )
formControlComment { form, creatingComment } =
    let
        commentField =
            Form.getFieldAsString "comment.text" form

        ( isValid, isInvalid_ ) =
            FormUtils.controlValidityState commentField

        isInvalid =
            creatingComment && isInvalid_

        commentFieldValue =
            Maybe.withDefault
                ""
                commentField.value
    in
        (FormUtils.formGrp
            Input.textArea
            commentField
            [ Attr.placeholder "Comment"
            , Attr.name "new-meal-comment"
            , Attr.id "new-meal-comment"
            , Attr.value commentFieldValue
            , Attr.class "autoExpand"
            ]
            { errorId = "new-meal-comment-error-id"
            , errors = Nothing
            }
            FormMsg
        )
            => isInvalid


formControlMeal : Model -> ( Html Msg, Bool )
formControlMeal { form } =
    let
        mealField =
            Form.getFieldAsString "meal" form

        ( isValid, isInvalid ) =
            FormUtils.controlValidityState mealField

        mealFieldValue =
            Maybe.withDefault
                ""
                mealField.value
    in
        (FormUtils.formGrp
            Input.textArea
            mealField
            [ Attr.placeholder "Meal"
            , Attr.name "new-meal-input"
            , Attr.id "new-meal-input"
            , Attr.value mealFieldValue
            , Attr.class "autoExpand"
            ]
            { errorId = "new-meal-input-error-id"
            , errors = Nothing
            }
            FormMsg
        )
            => isInvalid


formControlTime : Model -> ( Html Msg, Bool )
formControlTime model =
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
                , Attr.id "new-meal-time"
                , Attr.name "new-meal-time"
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
            [ Attr.id "new-meal-time-input-grpup" ]
            [ dateInput
            , FormUtils.textualError
                { errors = error
                , errorId = "new-meal-time-error-id"
                }
            ]
            => isInvalid


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style



-- form validation


validate : Bool -> Validation String FormValue
validate creatingComment =
    let
        validateText =
            if creatingComment == True then
                nonEmpty 3
            else
                Validate.succeed ""

        validateComment =
            Validate.succeed CommentValue
                |> Validate.andMap
                    (Validate.field
                        "text"
                        (validateText
                            |> withCustomError
                                "Comment must be at least 3 characters."
                        )
                    )
    in
        Validate.succeed FormValue
            |> Validate.andMap
                (Validate.field
                    "meal"
                    (nonEmpty 3
                        |> withCustomError
                            "Meal must be at least 3 characters."
                    )
                )
            |> Validate.andMap
                (Validate.field "comment" validateComment)



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
