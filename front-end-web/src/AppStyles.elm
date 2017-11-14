module AppStyles exposing (css, appNamespace)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import SharedStyles exposing (..)
import Html.CssHelpers exposing (Namespace, withNamespace)
import Css.Media exposing (mediaQuery)


css : Stylesheet
css =
    (stylesheet << namespace appNamespace.name)
        [ class
            ShowNoneMobile
            [ display none ]
        , class
            DisplayNoneMobileTableCell
            [ display none ]
        , mediaQuery
            [ "screen and (min-width: 768px)" ]
            [ class
                ShowOnlyMobile
                [ display none ]
            , class
                ShowNoneMobile
                [ display initial ]
            , class
                DisplayNoneMobileTableCell
                [ display tableCell ]
            ]
        ]


appNamespace : Namespace String class id msg
appNamespace =
    withNamespace "app"
