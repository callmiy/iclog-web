module Views.Util
    exposing
        ( cardTitle
        , formControlDateTimePicker
        )

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Css
import Date exposing (Date)
import Utils exposing ((=>), formatDateForForm)
import DateTimePicker
import DateTimePicker.Config as DateTimePickerConfig
    exposing
        ( DatePickerConfig
        , defaultDateTimePickerConfig
        , TimePickerConfig
        )
import Views.FormUtils as FormUtils


cardTitle : String -> Html msg
cardTitle title =
    Html.h6
        [ Attr.class "card-title"
        , styles
            [ Css.textAlignLast Css.end
            , Css.color (Css.rgb 212 198 198)
            ]
        ]
        [ Html.text title ]


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


formControlDateTimePicker :
    Maybe Date
    -> (DateTimePicker.State -> Maybe Date -> msg)
    -> DateTimePicker.State
    -> String
    -> ( Html msg, Bool, Bool, Maybe String )
formControlDateTimePicker maybeDate msg datePickerState label =
    let
        config =
            let
                defaultDateTimeConfig =
                    defaultDateTimePickerConfig msg

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

        ( isValid, isInvalid, error ) =
            case maybeDate of
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
                , Attr.id label
                , Attr.name label
                ]
                datePickerState
                maybeDate
    in
        ( Html.div
            [ Attr.id <| label ++ "-input-group" ]
            [ dateInput
            , FormUtils.textualError
                { errors = error
                , errorId = label ++ "-error-id"
                }
            ]
        , isValid
        , isInvalid
        , error
        )
