module Observation.Navigation exposing (nav)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Html.Events exposing (onClick)
import Css
import Router exposing (Route, Msg)


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


nav : Route -> Msg msg -> Html msg
nav showing msg =
    Html.div
        [ styles [ Css.height (Css.pct 100) ] ]
        [ Html.div
            [ styles
                [ Css.marginBottom (Css.rem 0.75)
                , Css.fontSize (Css.rem 1.3)
                ]
            ]
            [ changeViewIcon
                "new-observable-nav-icon"
                "New"
                "fa fa-plus-square"
                (msg Router.ObservationNew)
                (showing == Router.ObservationNew)
            , changeViewIcon
                "list-observables-nav-icon"
                "List"
                "fa fa-list"
                (msg Router.ObservationList)
                (showing == Router.ObservationList)
            ]
        ]


changeViewIcon :
    String
    -> String
    -> String
    -> msg
    -> Bool
    -> Html msg
changeViewIcon id_ title classNames msg showing =
    let
        styles_ others =
            styles
                ([ Css.paddingLeft (Css.px 0)
                 , Css.display Css.inline
                 , Css.marginRight (Css.rem 0.75)
                 ]
                    ++ others
                )

        attrs_ =
            [ Attr.class classNames

            -- , Attr.attribute "data-toggle" "tooltip"
            -- , Attr.attribute "data-placement" "bottom"
            , Attr.attribute "title" title
            , Attr.attribute "aria-hidden" "true"
            , Attr.id id_
            ]

        attrs =
            if showing then
                (styles_ [ Css.cursor Css.notAllowed ]) :: attrs_
            else
                [ (styles_ [ Css.cursor Css.pointer ]) ]
                    ++ [ onClick msg ]
                    ++ attrs_
    in
        Html.i
            attrs
            []
