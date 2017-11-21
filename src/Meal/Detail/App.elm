module Meal.Detail.App
    exposing
        ( Model
        , Msg(..)
        , Viewing(..)
        , FormValue
        , update
        , subscriptions
        , init
        , queryStore
        , commentControlId
        )

import Meal.Types
    exposing
        ( MealId
        , fromMealId
        , Comment
        , MealWithComments
        )
import Store exposing (Store, TimeZoneOffset)
import Date exposing (Date)
import DateTimePicker
import Meal.Channel as Channel exposing (ChannelState)
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
import Views.CommentEdit as CommentEdit exposing (CommentValue)


type alias Model =
    { meal : Maybe MealWithComments
    , viewing : Viewing
    , serverError : Maybe String
    , submitting : Bool
    , selectedDate : Maybe Date
    , datePickerState : DateTimePicker.State
    , editSuccess : Bool
    , form : Form String FormValue
    , creatingComment : Bool
    , commentForm : Maybe (Form String CommentValue)
    }


type alias FormValue =
    { meal : String
    , comment : CommentValue
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
        , creatingComment = False
        , commentForm = Nothing
        , form = Form.initial (initialFields "") <| validate False
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
    | SubmitForm MealWithComments
    | DismissEditSuccessInfo
    | ToggleCommentForm
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

        ChangeView viewing ->
            changeView viewing model
                ! []

        FormMsg formMsg ->
            { model
                | form =
                    Form.update (validate model.creatingComment) formMsg model.form
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
                    Form.update (validate model.creatingComment) Form.Submit model.form

                model_ =
                    { model | form = form_ }
            in
                case ( Form.getOutput form_, store.websocketUrl ) of
                    ( Just { meal, comment }, Just websocketUrl ) ->
                        let
                            tz =
                                Store.toTimeZoneVal
                                    store.tzOffset

                            time =
                                Maybe.map
                                    (formatDateISOWithTimeZone tz)
                                    model.selectedDate

                            params =
                                if model.creatingComment then
                                    { id = id
                                    , meal = Just meal
                                    , comment = Just comment
                                    , time = time
                                    }
                                else
                                    { id = id
                                    , meal = Just meal
                                    , comment = Nothing
                                    , time = time
                                    }

                            cmd =
                                Channel.update params
                                    |> Phoenix.push websocketUrl
                                    |> Cmd.map ChannelMsg
                        in
                            { model_ | submitting = True } => cmd

                    _ ->
                        model_ ! []

        DismissEditSuccessInfo ->
            { model | editSuccess = False } ! []

        ToggleCommentForm ->
            let
                ( model_, cmd ) =
                    CommentEdit.toggleCommentForm
                        model
                        revalidateForm
                        commentControlId
                        NoOp
            in
                model_ ! [ cmd ]

        ToggleAddComment ->
            let
                commentForm =
                    case model.commentForm of
                        Just _ ->
                            Nothing

                        Nothing ->
                            Just CommentEdit.initForm
            in
                { model | commentForm = commentForm } ! []

        CommentFormMsg formMsg ->
            { model
                | commentForm =
                    Maybe.andThen
                        (Just << Form.update (CommentEdit.validate True) formMsg)
                        model.commentForm
            }
                ! []

        SubmitCommentForm ->
            case model.commentForm of
                Just commentForm ->
                    let
                        form_ =
                            Form.update
                                (CommentEdit.validate True)
                                Form.Submit
                                commentForm
                    in
                        case ( Form.getOutput form_, model.meal, store.websocketUrl ) of
                            ( Just { text }, Just { id }, Just websocketUrl ) ->
                                let
                                    params =
                                        { text = text
                                        , mealId = id
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

        NoOp _ ->
            model ! []


mealReceived : MealWithComments -> Model -> Model
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
            , commentForm = Nothing
        }


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
        |> resetCreatingComment


resetForm : Model -> Model
resetForm ({ meal, form } as model) =
    case meal of
        Just ({ time } as meal_) ->
            { model
                | form =
                    Form.update
                        (validate False)
                        (Form.Reset <| initialFields meal_.meal)
                        form
                , selectedDate = Just time
                , editSuccess = False
            }
                |> resetCreatingComment
                |> Utils.unSubmit

        Nothing ->
            resetCreatingComment model |> Utils.unSubmit


editSuccess : Model -> Model
editSuccess model =
    { model | editSuccess = True }


resetCreatingComment : Model -> Model
resetCreatingComment model =
    { model | creatingComment = False }


validate : Bool -> Validation String FormValue
validate creatingComment =
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
            (Validate.field "comment" <| CommentEdit.validate creatingComment)


addComment : Comment -> Model -> Model
addComment comment ({ meal } as model) =
    { model
        | meal =
            Maybe.andThen
                (\m -> Just <| { m | comments = comment :: m.comments })
                meal
    }


nullifyCommentForm : Model -> Model
nullifyCommentForm model =
    { model | commentForm = Nothing }


commentControlId : String
commentControlId =
    "edit-meal-comment"



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none
