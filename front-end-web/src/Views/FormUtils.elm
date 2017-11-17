module Views.FormUtils
    exposing
        ( formGrp
        , errorMessage
        , formIsEmpty
        , controlValidityState
        , textualError
        , joinErrors
        , textualErrorBox
        , formControlValidator
        , formBtns
        )

import Html exposing (..)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Form.Input as Input exposing (Input)
import Form exposing (Form, FieldState)
import Form.Error exposing (ErrorValue(CustomError))
import Set
import Css
import Utils exposing (unquoteString)


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


formControlValidator :
    FieldState e String
    -> List (Attribute msg)
    -> Maybe a
    -> ( List (Attribute msg), Bool, Maybe (ErrorValue e) )
formControlValidator state additionalAttributes errors =
    let
        attributes =
            [ Attr.classList
                [ ( "form-control", True )
                , ( "is-invalid", isInvalid )
                , ( "is-valid", isValid )
                ]
            ]
                ++ additionalAttributes

        ( liveError, error ) =
            ( state.liveError, state.error )

        ( isValid_, isInvalid_ ) =
            controlValidityState state

        isValid =
            isValid_ && (errors == Nothing)

        isInvalid =
            isInvalid_ || (errors /= Nothing)
    in
        ( attributes, isInvalid, error )


type alias FormGrpErrorSetting =
    { errorId : String
    , errors : Maybe String
    }


formGrp :
    Input e String
    -> FieldState e String
    -> List (Attribute Form.Msg)
    -> FormGrpErrorSetting
    -> (Form.Msg -> msg)
    -> Html msg
formGrp control state additionalAttributes ({ errors } as errorSetting) msg =
    let
        ( attributes, isInvalid, error ) =
            formControlValidator state additionalAttributes errors
    in
        Html.map msg <|
            div
                [ Attr.class "blj" ]
                [ control state attributes
                , errorMessage errorSetting error isInvalid
                , textualError errorSetting
                ]


errorMessage :
    FormGrpErrorSetting
    -> Maybe (ErrorValue e)
    -> Bool
    -> Html msg
errorMessage errorSetting maybeError isInvalid =
    let
        toTextualError error =
            textualError
                { errorSetting
                    | errors =
                        toString error
                            |> Just
                }
    in
        case ( maybeError, isInvalid ) of
            ( Just (CustomError e), True ) ->
                toTextualError e

            ( Just error, True ) ->
                toTextualError error

            _ ->
                text ""


formIsEmpty : Form e o -> Bool
formIsEmpty =
    (Form.getChangedFields >> Set.isEmpty)


controlValidityState : FieldState e String -> ( Bool, Bool )
controlValidityState state =
    let
        ( liveError, error ) =
            ( state.liveError, state.error )

        isChanged =
            state.isChanged

        isValid =
            (isChanged == True)
                && (liveError == Nothing)
                && (error == Nothing)

        isInvalid =
            (isChanged == True)
                && ((liveError /= Nothing)
                        || (error /= Nothing)
                   )
    in
        ( isValid, isInvalid )


textualError : FormGrpErrorSetting -> Html msg
textualError { errors, errorId } =
    case errors of
        Nothing ->
            text ""

        Just error ->
            div
                [ Attr.style
                    [ ( "margin", "8px 0 0 0" )
                    , ( "fontWeight", "500" )
                    , ( "color", "#9f3a38" )
                    ]
                , Attr.id errorId
                ]
                [ text <| unquoteString error ]


joinErrors : String -> Maybe (List String) -> Maybe String
joinErrors field maybeListErrors =
    case maybeListErrors of
        Just errors ->
            Just <| field ++ ": " ++ String.join "\n" errors

        _ ->
            Nothing


textualErrorBox : Maybe String -> Html msg
textualErrorBox maybeMessage =
    case maybeMessage of
        Nothing ->
            text ""

        Just message ->
            div
                [ Attr.class "ui negative message" ]
                [ p [] [ text message ] ]


formBtns :
    List (Attribute msg)
    -> List (Attribute msg)
    -> String
    -> msg
    -> Html msg
formBtns attributesSubmit attributesReset label_ resetMsg =
    Html.div
        [ styles [ Css.displayFlex ] ]
        [ Html.button
            ([ styles [ Css.flex (Css.int 1) ]
             , Attr.class "btn btn-info"
             , Attr.type_ "submit"
             ]
                ++ attributesSubmit
            )
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
            ([ styles [ Css.marginLeft (Css.rem 4) ]
             , Attr.class "btn btn-outline-warning"
             , Attr.type_ "button"
             , onClick resetMsg
             ]
                ++ attributesReset
            )
            [ Html.text "Reset" ]
        ]
