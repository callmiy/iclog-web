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
        )

import Html exposing (..)
import Html.Attributes as Attr
import Form.Input as Input exposing (Input)
import Form exposing (Form, FieldState)
import Form.Error exposing (ErrorValue)
import Set
import Css


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
    case ( maybeError, isInvalid ) of
        ( Just error, True ) ->
            textualError
                { errorSetting
                    | errors = Just <| toString error
                }

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
                [ text error ]


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
