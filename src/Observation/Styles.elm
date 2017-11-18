module Observation.Styles exposing (css, observationNamespace)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import SharedStyles exposing (..)
import Html.CssHelpers exposing (Namespace, withNamespace)


css : Stylesheet
css =
    (stylesheet << namespace observationNamespace.name)
        [ class NewMeta
            [ border3 (px 1) solid (hex "#434857") |> important
            , padding4 (Css.rem 0.6) (Css.rem 0.2) (Css.rem 0) (Css.rem 0.2) |> important
            , marginBottom (Css.rem 0.5) |> important
            , borderRadius (px 5) |> important
            , position relative |> important
            ]
        , class NewMetaLegend
            [ position absolute
            , left (px 3)
            , top (px -10)
            ]
        , class NewMetaDismiss
            [ minWidth (pct 100)
            , cursor pointer
            ]
        ]


observationNamespace : Namespace String class id msg
observationNamespace =
    withNamespace "observation"
