module Sleep.Detail.App
    exposing
        ( Model
        , Msg(..)
        , Viewing(..)
        , FormValue
        , update
        , init
        , queryStore
        , commentControlId
        , emptyForm
        )

import Sleep.Types
    exposing
        ( SleepId
        , fromSleepId
        , SleepWithComments
        )
import Store exposing (Store, TimeZoneOffset)
import Date exposing (Date)
import DateTimePicker
import Sleep.Channel as Channel exposing (ChannelState)
import Form exposing (Form, FieldState)
import Form.Field as Field exposing (Field)
import Form.Validate as Validate exposing (Validation, withCustomError)
import Phoenix
import Utils
    exposing
        ( decodeErrorMsg
        , formatDateForForm
        , nonEmpty
        , (=>)
        , formatDateISOWithTimeZone
        )
import Comment exposing (Comment, CommentValue)


type alias Model =
    { sleep : Maybe SleepWithComments
    , viewing : Viewing
    , serverError : Maybe String
    , submitting : Bool
    , start : Maybe Date
    , end : Maybe Date
    , datePickerStart : DateTimePicker.State
    , datePickerEnd : DateTimePicker.State
    , editSuccess : Bool
    , editForm : Maybe (Form String FormValue)
    , creatingComment : Bool
    , commentForm : Maybe (Form String CommentValue)
    }


type alias FormValue =
    { comment : CommentValue
    }


initialFields : List ( String, Field )
initialFields =
    []


emptyForm : Form String FormValue
emptyForm =
    Form.initial initialFields <| validate False


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
        { sleep = Nothing
        , viewing = ViewingDetail
        , serverError = Nothing
        , submitting = False
        , start = Nothing
        , end = Nothing
        , datePickerStart = DateTimePicker.initialState
        , datePickerEnd = DateTimePicker.initialState
        , editSuccess = False
        , creatingComment = False
        , commentForm = Nothing
        , editForm = Nothing
        }
            ! [ cmd
              , DateTimePicker.initialCmd
                    DatePickerChangedStart
                    DateTimePicker.initialState
              , DateTimePicker.initialCmd
                    DatePickerChangedEnd
                    DateTimePicker.initialState
              ]


type Msg
    = ChannelMsg ChannelState
    | ChangeView Viewing
    | FormMsg Form.Msg
    | DatePickerChangedStart DateTimePicker.State (Maybe Date)
    | DatePickerChangedEnd DateTimePicker.State (Maybe Date)
    | ResetForm
    | SubmitForm SleepWithComments
    | DismissEditSuccessInfo
    | ToggleEditForm
    | NoOp ()
    | ToggleAddComment
    | CommentFormMsg Form.Msg
    | SubmitCommentForm


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
                        Ok sleep_ ->
                            sleepReceived sleep_ model
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log (decodeErrorMsg msg) err
                            in
                                model ! []

                Channel.UpdateSucceeds result ->
                    case result of
                        Ok sleep_ ->
                            (sleepReceived sleep_ model
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

                Channel.CommentSucceeds result ->
                    case result of
                        Ok comment ->
                            (addComment comment model
                                |> nullifyCommentForm
                            )
                                ! []

                        Err err ->
                            let
                                x =
                                    Debug.log (decodeErrorMsg msg) err
                            in
                                model ! []

                _ ->
                    model ! []

        SubmitForm { id } ->
            let
                form_ =
                    Form.update
                        (validate model.creatingComment)
                        Form.Submit
                        (Maybe.withDefault emptyForm model.editForm)

                model_ =
                    { model | editForm = Just form_ }
            in
                case ( Form.getOutput form_, store.websocketUrl ) of
                    ( Just { comment }, Just websocketUrl ) ->
                        let
                            tz =
                                Store.toTimeZoneVal
                                    store.tzOffset

                            start =
                                Maybe.map
                                    (formatDateISOWithTimeZone tz)
                                    model.start

                            end =
                                Maybe.map
                                    (formatDateISOWithTimeZone tz)
                                    model.end

                            params =
                                if model.creatingComment then
                                    { id = id
                                    , start = start
                                    , comment = Just comment
                                    , end = end
                                    }
                                else
                                    { id = id
                                    , start = start
                                    , comment = Nothing
                                    , end = end
                                    }

                            cmd =
                                Channel.update params
                                    |> Phoenix.push websocketUrl
                                    |> Cmd.map ChannelMsg
                        in
                            { model_ | submitting = True } => cmd

                    _ ->
                        model_ ! []

        ChangeView viewing ->
            changeView viewing model
                ! []

        FormMsg formMsg ->
            { model
                | editForm =
                    Maybe.andThen
                        (\form_ ->
                            Just <|
                                Form.update
                                    (validate model.creatingComment)
                                    formMsg
                                    form_
                        )
                        model.editForm
                , serverError = Nothing
            }
                => Cmd.none

        DatePickerChangedStart datePickerState maybeDate ->
            (compareDates
                { model
                    | datePickerStart = datePickerState
                    , start = maybeDate
                }
            )
                ! []

        DatePickerChangedEnd datePickerState maybeDate ->
            (compareDates
                { model
                    | datePickerEnd = datePickerState
                    , end = maybeDate
                }
            )
                ! []

        ResetForm ->
            resetForm model ! []

        DismissEditSuccessInfo ->
            { model | editSuccess = False } ! []

        ToggleEditForm ->
            let
                ( model_, cmd ) =
                    Comment.toggleCommentForm
                        model
                        revalidateForm
                        commentControlId
                        NoOp

                form_ =
                    if model_.creatingComment then
                        Just emptyForm
                    else
                        Nothing
            in
                { model_ | editForm = form_ } ! [ cmd ]

        ToggleAddComment ->
            let
                commentForm =
                    case model.commentForm of
                        Just _ ->
                            Nothing

                        Nothing ->
                            Just Comment.initForm
            in
                { model | commentForm = commentForm } ! []

        CommentFormMsg formMsg ->
            { model
                | commentForm =
                    Maybe.andThen
                        (Just << Form.update (Comment.validate True) formMsg)
                        model.commentForm
            }
                ! []

        SubmitCommentForm ->
            case model.commentForm of
                Just commentForm ->
                    let
                        form_ =
                            Form.update
                                (Comment.validate True)
                                Form.Submit
                                commentForm
                    in
                        case ( Form.getOutput form_, model.sleep, store.websocketUrl ) of
                            ( Just { text }, Just { id }, Just websocketUrl ) ->
                                let
                                    params =
                                        { text = text
                                        , sleepId = id
                                        }

                                    cmd =
                                        Channel.comment params
                                            |> Phoenix.push websocketUrl
                                            |> Cmd.map ChannelMsg
                                in
                                    model ! [ cmd ]

                            _ ->
                                { model | commentForm = Just form_ } ! []

                Nothing ->
                    model ! []

        _ ->
            model ! []


commentControlId : String
commentControlId =
    "detail-sleep-comment"


sleepReceived : SleepWithComments -> Model -> Model
sleepReceived sleep_ model =
    { model
        | sleep = Just sleep_
        , start = Just sleep_.start
        , end = Just sleep_.end
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
            , commentForm = Nothing
        }


resetForm : Model -> Model
resetForm ({ sleep, editForm } as model) =
    let
        model_ =
            case sleep of
                Just { start, end } ->
                    { model
                        | start = Just start
                        , end = Just end
                        , editSuccess = False
                        , serverError = Nothing
                    }
                        |> resetCreatingComment
                        |> Utils.unSubmit

                _ ->
                    model
    in
        resetCreatingComment model_ |> Utils.unSubmit


resetCreatingComment : Model -> Model
resetCreatingComment model =
    { model | creatingComment = False }


validate : Bool -> Validation String FormValue
validate creatingComment =
    Validate.succeed FormValue
        |> Validate.andMap
            (Validate.field "comment" <| Comment.validate creatingComment)


addComment : Comment -> Model -> Model
addComment comment ({ sleep } as model) =
    { model
        | sleep =
            Maybe.andThen
                (\m -> Just <| { m | comments = comment :: m.comments })
                sleep
    }


nullifyCommentForm : Model -> Model
nullifyCommentForm model =
    { model | commentForm = Nothing }


editSuccess : Model -> Model
editSuccess model =
    { model | editSuccess = True }


revalidateForm : Form.Msg -> Model -> Model
revalidateForm formMsg model =
    { model
        | editForm =
            Maybe.andThen
                (\form_ ->
                    Just <|
                        Form.update
                            (validate model.creatingComment)
                            formMsg
                            form_
                )
                model.editForm
        , serverError = Nothing
    }
        |> resetCreatingComment


compareDates : Model -> Model
compareDates ({ start, end } as model) =
    case ( start, end ) of
        ( Just start_, Just end_ ) ->
            let
                serverError =
                    case compare (Date.toTime start_) (Date.toTime end_) of
                        GT ->
                            Just "End time must be after start time!"

                        _ ->
                            Nothing
            in
                { model | serverError = serverError }

        _ ->
            model
