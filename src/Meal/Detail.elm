module Meal.Detail
    exposing
        ( Model
        , Msg(..)
        , update
        , view
        , subscriptions
        , init
        , queryStore
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onSubmit)
import Views.Nav exposing (nav)
import Router
import Meal.Types
    exposing
        ( Meal
        , MealId
        , fromMealId
        , Comment
        )
import Store exposing (Store, TimeZoneOffset)
import Date exposing (Date)
import DateTimePicker
import DateTimePicker.Config as DateTimePickerConfig
    exposing
        ( DatePickerConfig
        , defaultDateTimePickerConfig
        , TimePickerConfig
        )
import Meal.Channel as Channel exposing (ChannelState)
import Views.FormUtils as FormUtils
import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation, withCustomError)
import Form.Input as Input exposing (Input)
import Phoenix
import Utils
    exposing
        ( decodeErrorMsg
        , formatDateForForm
        , nonEmpty
        , (=>)
        , formatDateISOWithTimeZone
        )
import Css
import Views.CreationSuccessAlert as CreationSuccessAlert


type alias Model =
    { meal : Maybe Meal
    , viewing : Viewing
    , serverError : Maybe String
    , submitting : Bool
    , selectedDate : Maybe Date
    , datePickerState : DateTimePicker.State
    , editSuccess : Bool
    , form : Form String FormValue
    }


type alias FormValue =
    { meal : String
    }


initialFields : String -> List ( String, Field )
initialFields meal =
    [ ( "meal", Field.string meal )
    ]


init : String -> QueryStore -> ( Model, Cmd Msg )
init id_ { websocketUrl } =
    let
        url =
            Maybe.withDefault "" websocketUrl

        cmd =
            Channel.get id_
                |> Phoenix.push url
                |> Cmd.map ChannelMsg
    in
        { meal = Nothing
        , viewing = ViewingDetail
        , serverError = Nothing
        , submitting = False
        , selectedDate = Nothing
        , datePickerState = DateTimePicker.initialState
        , editSuccess = False
        , form = Form.initial (initialFields "") validate
        }
            ! [ cmd
              , DateTimePicker.initialCmd
                    DatePickerChanged
                    DateTimePicker.initialState
              ]


type Msg
    = ChannelMsg ChannelState
    | ChangeView Viewing
    | FormMsg Form.Msg
    | DatePickerChanged DateTimePicker.State (Maybe Date)
    | ResetForm
    | SubmitForm Meal
    | DismissEditSuccessInfo


type Viewing
    = ViewingDetail
    | ViewingEdit


type alias QueryStore =
    { websocketUrl : Maybe String
    , tzOffset : TimeZoneOffset
    }


queryStore : Store -> QueryStore
queryStore store =
    { websocketUrl = Store.getWebsocketUrl store
    , tzOffset = Store.getTimeZoneOffset store
    }


update : Msg -> Model -> QueryStore -> ( Model, Cmd Msg )
update msg model store =
    case msg of
        ChannelMsg channelState ->
            case channelState of
                Channel.GetSucceeds result ->
                    case result of
                        Ok meal_ ->
                            mealReceived meal_ model
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log (decodeErrorMsg msg) err
                            in
                                model ! []

                Channel.UpdateSucceeds result ->
                    case result of
                        Ok meal_ ->
                            (mealReceived meal_ model
                                |> Utils.unSubmit
                                |> changeView ViewingDetail
                                |> editSuccess
                            )
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log (decodeErrorMsg msg) err
                            in
                                (Utils.unSubmit model
                                    |> Utils.unknownServerError
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
                    { model | form = form_ }
            in
                case ( mealFromForm form_, store.websocketUrl ) of
                    ( Just meal, Just websocketUrl ) ->
                        let
                            tz =
                                Store.toTimeZoneVal
                                    store.tzOffset

                            cmd =
                                { meal = Just meal
                                , id = id
                                , time =
                                    Maybe.map
                                        (formatDateISOWithTimeZone tz)
                                        model.selectedDate
                                }
                                    |> Channel.update
                                    |> Phoenix.push websocketUrl
                                    |> Cmd.map ChannelMsg
                        in
                            { model_ | submitting = True } => cmd

                    _ ->
                        model_ ! []

        DismissEditSuccessInfo ->
            { model | editSuccess = False } ! []


mealReceived : Meal -> Model -> Model
mealReceived meal_ model =
    { model
        | meal = Just meal_
        , selectedDate = Just meal_.time
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


resetForm : Model -> Model
resetForm ({ meal, form } as model) =
    case meal of
        Just ({ time } as meal_) ->
            { model
                | form =
                    Form.update
                        validate
                        (Form.Reset <| initialFields meal_.meal)
                        form
                , selectedDate = Just time
                , editSuccess = False
            }

        Nothing ->
            model


mealFromForm : Form String FormValue -> Maybe String
mealFromForm form_ =
    Form.getOutput form_ |> Maybe.map .meal


editSuccess : Model -> Model
editSuccess model =
    { model | editSuccess = True }



-- VIEW


view : Model -> Html Msg
view ({ meal, viewing } as model) =
    let
        mainView =
            case meal of
                Nothing ->
                    Html.text ""

                Just meal_ ->
                    case viewing of
                        ViewingDetail ->
                            viewDetail meal_ model

                        ViewingEdit ->
                            viewEdit meal_ model
    in
        Html.div [ Attr.id "meal-detail" ]
            [ nav Nothing Router.MealList Router.MealNew "meal"
            , mainView
            ]


viewDetail : Meal -> Model -> Html Msg
viewDetail ({ meal, time, comments } as meal_) model =
    let
        alertId =
            if model.editSuccess == True then
                Just <| fromMealId meal_.id
            else
                Nothing
    in
        Html.div
            [ Attr.class "card" ]
            [ Html.div
                [ Attr.class "card-body" ]
                [ CreationSuccessAlert.view
                    { id = alertId
                    , route = Nothing
                    , label = "meal"
                    , dismissMsg = Just DismissEditSuccessInfo
                    }
                , Html.p
                    [ Attr.class "card-text" ]
                    [ Html.text meal ]
                , Html.div
                    [ Attr.class "card-link"
                    , styles
                        [ Css.displayFlex
                        , Css.flexDirection Css.rowReverse
                        ]
                    ]
                    [ Html.i
                        [ Attr.class "fa fa-pencil-square-o"
                        , styles
                            [ Css.cursor Css.pointer
                            , Css.width (Css.px 10)
                            ]
                        , onClick <| ChangeView ViewingEdit
                        , Attr.id "detail-meal-show-edit-display"
                        ]
                        []
                    ]
                , commentsView comments
                ]
            , Html.div
                [ Attr.class "card-footer text-muted" ]
                [ Html.text <| formatDateForForm time ]
            ]


commentsView : List Comment -> Html Msg
commentsView comments =
    case comments of
        [] ->
            Html.text ""

        comments_ ->
            Html.ul
                [ Attr.class "list-group list-group-flush"
                , styles [ Css.marginTop (Css.px 10) ]
                ]
            <|
                List.map commentView comments_


commentView : Comment -> Html Msg
commentView { text, insertedAt } =
    Html.li
        [ Attr.class "card" ]
        [ Html.div
            [ Attr.class "card-header"
            , styles [ Css.padding2 (Css.px 0) (Css.px 5) ]
            ]
            []
        , Html.div
            [ Attr.class "card-body"
            , styles [ Css.padding2 (Css.rem 0.5) (Css.rem 0.5) ]
            ]
            [ Html.p
                [ Attr.class "card-text" ]
                [ Html.text text ]
            ]
        , Html.div
            [ Attr.class "card-footer text-muted"
            , styles
                [ Css.fontSize (Css.rem 0.92)
                , Css.padding2 (Css.px 0) (Css.px 5)
                , Css.displayFlex
                , Css.flexDirection Css.rowReverse
                ]
            ]
            [ Html.div
                []
                [ Html.text <| formatDateForForm insertedAt ]
            ]
        ]


viewEdit : Meal -> Model -> Html Msg
viewEdit ({ meal, time, comments } as meal_) ({ viewing } as model) =
    let
        ( mealControl, mealInvalid ) =
            formControlMeal meal model

        ( timeControl, timeInvalid ) =
            formControlTime model

        label_ =
            case model.submitting of
                True ->
                    "Submitting..."

                False ->
                    "Submit"

        mealChanged =
            case mealFromForm model.form of
                Nothing ->
                    True

                Just aMeal ->
                    meal /= aMeal

        timeChanged =
            Maybe.map formatDateForForm model.selectedDate
                /= (Just <| formatDateForForm time)

        disableSubmitBtn =
            timeInvalid
                || mealInvalid
                || ([] /= Form.getErrors model.form)
                || (model.submitting == True)
                || (mealChanged == False && timeChanged == False)

        disableResetBtn =
            (model.submitting == True)
                || (mealChanged == False && timeChanged == False)
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
                        [ Attr.class "card-body edit-meal-form"
                        , Attr.novalidate True
                        , Attr.id "edit-meal-form"
                        , onSubmit <| SubmitForm meal_
                        ]
                        [ Html.div
                            [ Attr.class "edit-meal-form-controls"
                            , Attr.id "edit-meal-form-controls"
                            , styles [ Css.marginBottom (Css.rem 1) ]
                            ]
                            [ mealControl
                            , timeControl
                            , Html.div
                                [ styles [ Css.marginTop (Css.px 10) ] ]
                                [ FormUtils.formBtns
                                    [ Attr.disabled disableSubmitBtn
                                    , Attr.name "edit-meal-submit-btn"
                                    ]
                                    [ Attr.disabled disableResetBtn
                                    , Attr.name "edit-meal-reset-btn"
                                    ]
                                    label_
                                    ResetForm
                                ]
                            ]
                        , Html.div
                            [ Attr.class "card-footer"
                            , styles [ Css.padding (Css.px 0) ]
                            ]
                            [ Html.i
                                [ Attr.class "card-link fa fa-eye"
                                , styles [ Css.cursor Css.pointer ]
                                , onClick <| ChangeView ViewingDetail
                                , styles [ Css.display Css.inline ]
                                , Attr.id "detail-meal-show-detail-display"
                                ]
                                []
                            ]
                        ]
                    ]
                ]
            ]


formControlMeal : String -> Model -> ( Html Msg, Bool )
formControlMeal meal { form } =
    let
        mealField =
            Form.getFieldAsString "meal" form

        ( isValid, isInvalid ) =
            FormUtils.controlValidityState mealField

        mealFieldValue =
            Maybe.withDefault
                meal
                mealField.value
    in
        (FormUtils.formGrp
            Input.textArea
            mealField
            [ Attr.placeholder "Meal"
            , Attr.name "edit-meal-input"
            , Attr.value mealFieldValue
            , Attr.class "autoExpand"
            ]
            { errorId = "edit-meal-input-error-id"
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
                , Attr.id "edit-meal-time"
                , Attr.name "edit-meal-time"
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
            [ Attr.id "edit-meal-time-input-grpup" ]
            [ dateInput
            , FormUtils.textualError
                { errors = error
                , errorId = "edit-meal-time-error-id"
                }
            ]
            => isInvalid


validate : Validation String FormValue
validate =
    Validate.succeed FormValue
        |> Validate.andMap
            (Validate.field
                "meal"
                (nonEmpty 3
                    |> withCustomError "Meal must be at least 3 characters."
                )
            )


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
