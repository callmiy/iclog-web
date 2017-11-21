module Meal.Util exposing (cardTitle)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Css


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
