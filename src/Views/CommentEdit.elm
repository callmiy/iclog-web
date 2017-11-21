module Views.CommentEdit
    exposing
        ( CommentValue
        , view
        , formControl3
        , formControl4
        , validate
        , toggleCommentForm
        , initForm
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
import Utils exposing ((=>), nonEmpty, focusEl, (<=>))


type alias CommentValue =
    { text : String }


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


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style
