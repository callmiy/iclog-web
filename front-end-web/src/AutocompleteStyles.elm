module AutocompleteStyles exposing (css, autocompleteNamespace)

import Css exposing (..)
import Css.Namespace exposing (namespace)
import SharedStyles exposing (..)
import Html.CssHelpers exposing (Namespace, withNamespace)


css : Stylesheet
css =
    (stylesheet << namespace autocompleteNamespace.name)
        [ class AutocompleteMenu
            [ position relative |> important
            , marginTop (px 5)
            , backgroundColor (hex "#ffffff")
            , color (hex "#000000")
            , border3 (px 1) solid (hex "#ddd")
            , borderRadius (px 3)
            , boxShadow4 (px 0) (px 0) (px 5) (rgba 0 0 0 0.1)
            , minWidth (px 120)
            ]
        , class AutocompleteItem
            [ display block
            , padding2 (px 5) (px 10)
            , borderBottom3 (px 1) solid (hex "#ddd")
            , cursor pointer
            ]
        , class KeySelected
            [ backgroundColor (hex "#3366FF")
            ]
        , class MouseSelected
            [ backgroundColor (hex "#ececec")
            ]
        , class AutocompleteList
            [ listStyle none
            , padding (px 0)
            , margin auto
            , maxHeight (px 200)
            , overflowY auto
            ]
        ]


autocompleteNamespace : Namespace String class id msg
autocompleteNamespace =
    withNamespace "autocomplete"
