module Observation.Navigation exposing (nav)

import Html exposing (Html, Attribute)
import Html.Attributes as Attr
import Css
import Router exposing (Route, Msg)
import Utils exposing ((=>))


styles : List Css.Style -> Attribute msg
styles =
    Css.asPairs >> Attr.style


nav : Maybe Route -> Html msg
nav maybeCurrentRoute =
    let
        currentRoute route =
            case maybeCurrentRoute of
                Nothing ->
                    False

                Just r ->
                    r == route
    in
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
                    (currentRoute Router.ObservationNew)
                    Router.ObservationNew
                , changeViewIcon
                    "list-observables-nav-icon"
                    "List"
                    "fa fa-list"
                    (currentRoute Router.ObservationList)
                    Router.ObservationList
                ]
            ]


changeViewIcon :
    String
    -> String
    -> String
    -> Bool
    -> Route
    -> Html msg
changeViewIcon id_ title classNames showing route =
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
            , Attr.attribute "title" title
            , Attr.attribute "aria-hidden" "true"
            , Attr.id id_
            ]

        ( attrs, domEl ) =
            if showing then
                (styles_ [ Css.cursor Css.notAllowed ])
                    :: attrs_
                    => Html.i
            else
                [ (styles_ [ Css.cursor Css.pointer ]) ]
                    ++ [ Router.href route ]
                    ++ attrs_
                    => Html.a
    in
        domEl attrs []
