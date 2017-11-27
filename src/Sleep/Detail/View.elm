module Sleep.Detail.View exposing (view)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick, onSubmit)
import Views.Nav exposing (nav)
import Router
import Views.FormUtils as FormUtils
import Css
import Views.CreationSuccessAlert as CreationSuccessAlert
import Sleep.Detail.App
    exposing
        ( Model
        , Msg(..)
        , Viewing(..)
        , FormValue
        , commentControlId
        , emptyForm
        )
import Sleep.Types
    exposing
        ( SleepWithComments
        , fromSleepId
        , sleepDuration
        )
import Utils
    exposing
        ( formatDateForForm
        , (=>)
        , nonBreakingSpace
        )
import Form exposing (Form)
import Views.Util exposing (cardTitle, formControlDateTimePicker)
import Comment exposing (Comment, CommentValue, commentsView)


view : Model -> Html Msg
view ({ sleep, viewing } as model) =
    let
        mainView =
            case sleep of
                Nothing ->
                    Html.text ""

                Just sleep_ ->
                    case viewing of
                        ViewingDetail ->
                            viewDetail sleep_ model

                        ViewingEdit ->
                            viewEdit sleep_ model
    in
        Html.div [ Attr.id "sleep-detail" ]
            [ nav Nothing Router.SleepList Router.SleepNew "sleep"
            , mainView
            ]


viewDetail : SleepWithComments -> Model -> Html Msg
viewDetail ({ start, end, comments } as sleep_) model =
    let
        alertId =
            if model.editSuccess == True then
                Just <| fromSleepId sleep_.id
            else
                Nothing
    in
        Html.div
            [ Attr.class "card" ]
            [ Html.div
                [ Attr.class "card-body" ]
                [ cardTitle "Details"
                , CreationSuccessAlert.view
                    { id = alertId
                    , route = Nothing
                    , label = "sleep Details"
                    , dismissMsg = Just DismissEditSuccessInfo
                    }
                , Html.p
                    [ Attr.class "card-text" ]
                    [ Html.div
                        []
                        [ Html.text <|
                            "From: "
                                ++ (List.repeat 6 nonBreakingSpace |> String.join "")
                                ++ (formatDateForForm start)
                        ]
                    , Html.div
                        []
                        [ Html.text <|
                            "To: "
                                ++ (List.repeat 11 nonBreakingSpace |> String.join "")
                                ++ (formatDateForForm end)
                        ]
                    , Html.div
                        []
                        [ Html.text <|
                            "Duration: "
                                ++ (sleepDuration start end)
                        ]
                    ]
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
                            , Css.maxWidth (Css.px 10)
                            , Css.marginRight (Css.px 5)
                            ]
                        , onClick <| ChangeView ViewingEdit
                        , Attr.id "detail-sleep-show-edit-display"
                        ]
                        []
                    , case model.commentForm of
                        Just _ ->
                            Html.div [] []

                        Nothing ->
                            Comment.addCommentToggle
                                ToggleAddComment
                                "detail-sleep-add-comment-toggle"
                    ]
                , Html.div
                    [ styles [ Css.marginTop (Css.px 10) ] ]
                    [ viewCommentForm model.commentForm ]
                , commentsView comments
                ]
            ]


viewCommentForm : Maybe (Form String CommentValue) -> Html Msg
viewCommentForm maybeForm =
    case maybeForm of
        Nothing ->
            Html.text ""

        Just form_ ->
            let
                ( dom, _, valid ) =
                    Comment.formControl3
                        "text"
                        form_
                        "sleep-add-comment"
                        CommentFormMsg

                actionStyles =
                    [ Css.cursor Css.pointer
                    ]

                submitView =
                    if valid == True then
                        Html.i
                            [ Attr.class "fa fa-check"
                            , Attr.attribute "aria-hidden" "true"
                            , Attr.id "sleep-detail-add-comment-submit"
                            , onClick SubmitCommentForm
                            , styles
                                (actionStyles
                                    ++ [ Css.color (Css.rgb 40 167 69)
                                       , Css.padding (Css.px 0)
                                       , Css.marginTop (Css.rem 1)
                                       ]
                                )
                            ]
                            []
                    else
                        Html.div [] []
            in
                Html.div
                    [ Attr.class "adding-new-comment-only"
                    , styles [ Css.displayFlex ]
                    ]
                    [ Html.div
                        [ styles
                            [ Css.displayFlex
                            , Css.flexDirection Css.column
                            , Css.marginRight (Css.px 5)
                            ]
                        ]
                        [ Html.i
                            [ Attr.class "fa fa-ban"
                            , Attr.attribute "aria-hidden" "true"
                            , Attr.id "sleep-detail-add-comment-dismiss"
                            , styles
                                (actionStyles
                                    ++ [ Css.padding (Css.px 0)
                                       , Css.color (Css.rgb 255 59 48)
                                       , Css.marginTop (Css.rem 0.3)
                                       ]
                                )
                            , onClick ToggleAddComment
                            ]
                            []
                        , submitView
                        ]
                    , Html.div
                        [ styles [ Css.flex (Css.int 1) ] ]
                        [ dom ]
                    ]


viewEdit : SleepWithComments -> Model -> Html Msg
viewEdit ({ start, end, comments } as sleep_) ({ viewing, serverError } as model) =
    let
        ( startControl, _, startInvalid, _ ) =
            formControlDateTimePicker
                model.start
                DatePickerChangedStart
                model.datePickerStart
                "detail-sleep-edit-start"

        ( endControl, _, endInvalid, _ ) =
            formControlDateTimePicker
                model.end
                DatePickerChangedEnd
                model.datePickerEnd
                "detail-sleep-edit-end"

        form_ =
            (Maybe.withDefault emptyForm model.editForm)

        ( commentControl, commentInvalid, commentValid ) =
            Comment.formControl4
                form_
                commentControlId
                FormMsg
                model.creatingComment

        label_ =
            case model.submitting of
                True ->
                    "Submitting..."

                False ->
                    "Submit"

        startChanged =
            Maybe.map formatDateForForm model.start
                /= (Just <| formatDateForForm start)

        endChanged =
            Maybe.map formatDateForForm model.end
                /= (Just <| formatDateForForm end)

        disableSubmitBtn =
            (model.submitting == True)
                || startInvalid
                || endInvalid
                || commentInvalid
                || (serverError /= Nothing)
                || ([] /= Form.getErrors form_)
                || (startChanged
                        == False
                        && endChanged
                        == False
                        && commentValid
                        == False
                   )

        disableResetBtn =
            model.submitting == True
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
                        [ Attr.class "card-body edit-sleep-form"
                        , Attr.novalidate True
                        , Attr.id "edit-sleep-form"
                        , onSubmit <| SubmitForm sleep_
                        ]
                        [ cardTitle "Edit"
                        , Html.div
                            [ Attr.class "card-link"
                            , styles
                                [ Css.displayFlex
                                , Css.flexDirection Css.rowReverse
                                , Css.marginBottom (Css.px 10)
                                ]
                            ]
                            [ Html.i
                                [ Attr.class "fa fa-eye"
                                , styles [ Css.cursor Css.pointer ]
                                , onClick <| ChangeView ViewingDetail
                                , styles
                                    [ Css.maxWidth (Css.px 0)
                                    , Css.marginRight (Css.px 8)
                                    ]
                                , Attr.id "detail-sleep-show-detail-display"
                                ]
                                []
                            , (if model.creatingComment == True then
                                Html.text ""
                               else
                                Html.i
                                    [ Attr.class "fa fa-comment"
                                    , styles [ Css.cursor Css.pointer ]
                                    , onClick ToggleEditForm
                                    , styles
                                        [ Css.maxWidth (Css.px 0)
                                        , Css.marginRight (Css.px 10)
                                        ]
                                    , Attr.id
                                        "comment-edit-view-helper-reveal-composite-comment-id"
                                    ]
                                    []
                              )
                            ]
                        , Html.div
                            [ Attr.class "edit-sleep-form-controls"
                            , Attr.id "edit-sleep-form-controls"
                            , styles [ Css.marginBottom (Css.rem 1) ]
                            ]
                            [ FormUtils.textualErrorBox serverError
                            , startControl
                            , Html.div
                                [ styles [ Css.marginTop (Css.rem 1) ] ]
                                [ endControl ]
                            , Comment.view
                                commentControl
                                model.creatingComment
                                ToggleEditForm
                            ]
                        , FormUtils.formBtns
                            [ Attr.disabled disableSubmitBtn
                            , Attr.name "edit-sleep-submit-btn"
                            , Attr.id "edit-sleep-submit-btn"
                            ]
                            [ Attr.disabled disableResetBtn
                            , Attr.name "edit-sleep-reset-btn"
                            ]
                            label_
                            ResetForm
                        ]
                    ]
                ]
            ]


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style
