module Comment
    exposing
        ( Comment
        , CommentValue
        , fromCommentId
        , toCommentId
        , commentVarSpec
        , view
        , formControl3
        , formControl4
        , validate
        , toggleCommentForm
        , initForm
        , addCommentToggle
        , commentResponse
        , commentsView
        , commentView
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Css
import Views.FormUtils as FormUtils
import Form exposing (Form)
import Form.Input as Input
import Form.Field as Field
import Form.Validate as Validate exposing (Validation, withCustomError)
import Utils
    exposing
        ( (=>)
        , nonEmpty
        , focusEl
        , (<=>)
        , formatDateForForm
        )
import Date exposing (Date)
import GraphQL.Request.Builder.Variable as Var exposing (VariableSpec)
import GraphQL.Request.Builder as Grb exposing (ValueSpec)


type alias Comment =
    { id : CommentId
    , text : String
    , insertedAt : Date
    }


type CommentId
    = CommentId String


toCommentId : String -> CommentId
toCommentId id_ =
    CommentId id_


fromCommentId : CommentId -> String
fromCommentId (CommentId id_) =
    id_


type alias CommentValue =
    { text : String }


commentVarSpec : VariableSpec Var.NonNull CommentValue
commentVarSpec =
    Var.object
        "Comment"
        [ Var.field "text" .text Var.string ]


commentResponse : ValueSpec Grb.NonNull Grb.ObjectType Comment vars
commentResponse =
    Grb.object Comment
        |> Grb.with (Grb.field "id" [] (Grb.map toCommentId Grb.id))
        |> Grb.with (Grb.field "text" [] Grb.string)
        |> Grb.with (Grb.field "insertedAt" [] Utils.dateTimeType)


view : Html msg -> Bool -> msg -> Html msg
view commentControl creatingComment msg =
    if creatingComment then
        Html.div
            [ styles
                [ Css.displayFlex
                , Css.marginTop (Css.px 10)
                ]
            ]
            [ Html.i
                [ Attr.class "fa fa-minus"
                , Attr.attribute "aria-hidden" "true"
                , styles
                    [ Css.paddingLeft (Css.px 0)
                    , Css.width (Css.pct 10)
                    , Css.cursor Css.pointer
                    , Css.paddingTop (Css.pct 5)
                    , Css.color (Css.rgb 216 41 41)
                    , Css.height (Css.pct 1)
                    ]
                , onClick msg
                ]
                []
            , Html.div
                [ styles [ Css.flex (Css.int 1) ] ]
                [ commentControl ]
            ]
    else
        Html.text ""


formControl3 :
    String
    -> Form validation formValues
    -> String
    -> (Form.Msg -> msg)
    -> ( Html msg, Bool, Bool )
formControl3 selector form label formMsg =
    let
        commentField =
            Form.getFieldAsString selector form

        ( isValid, isInvalid ) =
            FormUtils.controlValidityState commentField

        commentFieldValue =
            Maybe.withDefault
                ""
                commentField.value
    in
        (<=>)
            (FormUtils.formGrp
                Input.textArea
                commentField
                [ Attr.placeholder "Comment"
                , Attr.name label
                , Attr.id label
                , Attr.value commentFieldValue
                , Attr.class "autoExpand"
                ]
                { errorId = label ++ "-comment-error-id"
                , errors = Nothing
                }
                formMsg
            )
            isInvalid
            isValid


formControl4 :
    Form validation formValues
    -> String
    -> (Form.Msg -> msg)
    -> Bool
    -> ( Html msg, Bool, Bool )
formControl4 form label formMsg creatingComment =
    let
        ( dom_, isInvalid_, isValid ) =
            formControl3 "comment.text" form label formMsg

        isInvalid =
            creatingComment && isInvalid_
    in
        (<=>) dom_ isInvalid isValid


validate : Bool -> Validation String CommentValue
validate creatingComment =
    let
        validateText =
            if creatingComment == True then
                nonEmpty 3
            else
                Validate.succeed ""
    in
        Validate.succeed CommentValue
            |> Validate.andMap
                (Validate.field
                    "text"
                    (validateText
                        |> withCustomError
                            "Comment must be at least 3 characters."
                    )
                )


toggleCommentForm :
    { r | creatingComment : Bool }
    -> (Form.Msg -> { r | creatingComment : Bool } -> { r | creatingComment : Bool })
    -> String
    -> (() -> msg)
    -> ( { r | creatingComment : Bool }, Cmd msg )
toggleCommentForm model revalidateForm commentId msg =
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
                , focusEl commentId msg
                )
    in
        model_ => cmd


initForm : Form String CommentValue
initForm =
    Form.initial [] <| validate False


addCommentToggle : msg -> String -> Html msg
addCommentToggle msg id_ =
    Html.i
        [ Attr.class "fa fa-comment"
        , styles
            [ Css.cursor Css.pointer
            , Css.maxWidth (Css.px 10)
            , Css.marginRight (Css.rem 1)
            ]
        , onClick msg
        , Attr.id id_
        ]
        []


commentsView : List Comment -> Html msg
commentsView comments =
    case comments of
        [] ->
            Html.text ""

        comments_ ->
            let
                sortWith_ a b =
                    case compare (Date.toTime a.insertedAt) (Date.toTime b.insertedAt) of
                        GT ->
                            LT

                        LT ->
                            GT

                        EQ ->
                            EQ
            in
                Html.ul
                    [ Attr.class "list-group list-group-flush"
                    , styles
                        [ Css.marginTop (Css.px 10)
                        , Css.border3
                            (Css.px 1)
                            (Css.solid)
                            (Css.rgb 119 119 119)
                        , Css.padding (Css.rem 0.1)
                        ]
                    ]
                <|
                    List.map commentView (List.sortWith sortWith_ comments_)


commentView : Comment -> Html msg
commentView { text, insertedAt } =
    Html.li
        [ Attr.class "card viewing-comment"
        , styles [ Css.borderRadius (Css.px 0) ]
        ]
        [ Html.div
            [ Attr.class "card-body"
            , styles [ Css.padding2 (Css.rem 0.1) (Css.rem 0.3) ]
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


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style
