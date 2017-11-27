module Sleep.New
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
import Form.Validate as Validate exposing (Validation, withCustomError)
import Date exposing (Date)
import Utils
    exposing
        ( (=>)
        , nonEmpty
        , formatDateForForm
        , formatDateISOWithTimeZone
        , unSubmit
        , unknownServerError
        , decodeErrorMsg
        , focusEl
        , getDateNow
        )
import DateTimePicker
import Sleep.Types exposing (SleepId, fromSleepId)
import Store exposing (Store, TimeZoneOffset)
import Css
import Views.Nav exposing (nav)
import Router
import Views.FormUtils as FormUtils
import Sleep.Channel as Channel exposing (ChannelState)
import Phoenix
import Views.CreationSuccessAlert as CreationSuccessAlert
import Comment exposing (CommentValue)
import Views.Util exposing (cardTitle, formControlDateTimePicker)


type alias Model =
    { form : Form String FormValue
    , serverError : Maybe String
    , submitting : Bool
    , creatingComment : Bool
    , startDate : Maybe Date
    , datePickerState : DateTimePicker.State
    , newSleep : Maybe SleepId
    }


type alias FormValue =
    { comment : CommentValue
    }


initialFields : List ( String, Field )
initialFields =
    []


defaults : Model
defaults =
    { form = Form.initial initialFields <| validate False
    , serverError = Nothing
    , submitting = False
    , creatingComment = False
    , newSleep = Nothing
    , startDate = Nothing
    , datePickerState = DateTimePicker.initialState
    }


init : ( Model, Cmd Msg )
init =
    defaults
        ! [ focusEl "new-sleep-input" NoOp
          , DateTimePicker.initialCmd
                DatePickerInitialMsg
                DateTimePicker.initialState
          , getDateNow Today
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
                | startDate = Just today
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
                , startDate = maybeDate
            }
                ! []

        ToggleCommentForm ->
            let
                ( model_, cmd ) =
                    Comment.toggleCommentForm
                        model
                        revalidateForm
                        commentControlId
                        NoOp
            in
                model_ ! [ cmd ]

        ResetForm ->
            resetForm model ! [ getDateNow Today ]

        ChannelMsg channelState ->
            case channelState of
                Channel.CreateSucceeds sleepId_ ->
                    case sleepId_ of
                        Ok sleepId ->
                            { defaults | newSleep = Just sleepId }
                                ! [ getDateNow Today ]

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
                case ( Form.getOutput newForm, model.startDate, store.websocketUrl ) of
                    ( Just { comment }, Just date, Just websocketUrl ) ->
                        let
                            start =
                                formatDateISOWithTimeZone
                                    (Store.toTimeZoneVal
                                        store.tzOffset
                                    )
                                    date

                            params =
                                if model.creatingComment then
                                    { start = start
                                    , comment = Just comment
                                    }
                                else
                                    { start = start
                                    , comment = Nothing
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

        NoOp _ ->
            ( model, Cmd.none )


validate : Bool -> Validation String FormValue
validate creatingComment =
    Validate.succeed FormValue
        |> Validate.andMap
            (Validate.field "comment" <| Comment.validate creatingComment)


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
        , newSleep = Nothing
        , datePickerState = DateTimePicker.initialState
    }



-- VIEW


commentControlId : String
commentControlId =
    "new-sleep-comment"


view : Model -> Html Msg
view ({ form, serverError, submitting } as model) =
    let
        ( commentControl, commentInvalid, _ ) =
            Comment.formControl4
                model.form
                commentControlId
                FormMsg
                model.creatingComment

        ( startControl, startInvalid ) =
            formControlStart model

        label_ =
            case submitting of
                True ->
                    "Submitting.."

                False ->
                    "Submit"

        disableSubmitBtn =
            startInvalid
                || commentInvalid
                || ([] /= Form.getErrors form)
                || (model.submitting == True)
    in
        Html.div []
            [ nav
                (Just Router.SleepNew)
                Router.SleepList
                Router.SleepNew
                "sleep"
            , CreationSuccessAlert.view
                { id = (Maybe.map fromSleepId model.newSleep)
                , route = Just Router.SleepDetail
                , label = "sleep"
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
                            [ Attr.class "card-body new-sleep-form"
                            , Attr.novalidate True
                            , Attr.id "new-sleep-form"
                            , onSubmit SubmitForm
                            ]
                            [ FormUtils.textualErrorBox model.serverError
                            , cardTitle "New Sleep"
                            , case model.creatingComment of
                                True ->
                                    Html.div [] []

                                False ->
                                    Html.div
                                        [ styles
                                            [ Css.displayFlex
                                            , Css.flexDirection Css.rowReverse
                                            , Css.marginBottom (Css.rem 0.6)
                                            ]
                                        ]
                                        [ Comment.addCommentToggle
                                            ToggleCommentForm
                                            "new-sleep-sleep-comment-toggle"
                                        ]
                            , Html.div
                                [ Attr.class "new-sleep-form-controls"
                                , Attr.id "new-sleep-form-controls"
                                , styles [ Css.marginBottom (Css.rem 1) ]
                                ]
                                [ startControl
                                , Comment.view
                                    commentControl
                                    model.creatingComment
                                    ToggleCommentForm
                                ]
                            , FormUtils.formBtns
                                [ Attr.disabled disableSubmitBtn
                                , Attr.name "new-sleep-submit-btn"
                                ]
                                [ Attr.disabled (model.submitting == True)
                                , Attr.name "new-sleep-reset-btn"
                                ]
                                label_
                                ResetForm
                            ]
                        ]
                    ]
                ]
            ]


formControlStart : Model -> ( Html Msg, Bool )
formControlStart model =
    let
        ( dateInput, isValid, isInvalid, error ) =
            formControlDateTimePicker
                model.startDate
                DatePickerChanged
                model.datePickerState
                "new-sleep-start"
    in
        Html.div
            [ Attr.id "new-sleep-start-input-grpup" ]
            [ dateInput ]
            => isInvalid


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style



-- SUBSCRIPTION


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
