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
formControlValidator state additionalAttributes otherErrors =
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
            isValid_ && (otherErrors == Nothing)

        isInvalid =
            isInvalid_ || (otherErrors /= Nothing)
    in
        ( attributes, isInvalid, error )


formGrp :
    Input e String
    -> FieldState e String
    -> List (Attribute Form.Msg)
    -> Maybe String
    -> (Form.Msg -> msg)
    -> Html msg
formGrp control state additionalAttributes otherErrors msg =
    let
        ( attributes, isInvalid, error ) =
            formControlValidator state additionalAttributes otherErrors
    in
        Html.map msg <|
            div
                [ Attr.class "blj" ]
                [ control state attributes
                , errorMessage error isInvalid
                , textualError otherErrors
                ]


errorMessage :
    Maybe (ErrorValue e)
    -> Bool
    -> Html msg
errorMessage maybeError isInvalid =
    case ( maybeError, isInvalid ) of
        ( Just error, True ) ->
            error
                |> toString
                |> Just
                |> textualError

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


textualError : Maybe String -> Html msg
textualError maybeError =
    case maybeError of
        Nothing ->
            text ""

        Just error ->
            div
                [ Attr.style
                    [ ( "margin", "8px 0 0 0" )
                    , ( "fontWeight", "500" )
                    , ( "color", "#9f3a38" )
                    ]
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
